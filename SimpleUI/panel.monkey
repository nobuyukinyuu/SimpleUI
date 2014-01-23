Import ui
Import widget
Import InputPointers

'Summary:  Provides a 2d panel which can be dragged in any direction.
Class ScrollablePanel Extends Widget
	'Base stuff
	Field cx:Float, cy:Float, cw:Float, ch:Float   'Content dimenions
	Field z:Float = 1  'Current zoom level
	
	'Scroll elements
	Field Scrolling:Bool 'Is the control scrolling?
	Field holding:Bool 'Is the user holding down the mouse button?
	Field clickStart:Bool 'Is the user holding down the button for a (non-drag) click?	

	Field firstX:Float, firstY:Float 'Persistent touch origin.
	Field xMomentum:Float, yMomentum:Float, xOrigin:Float, yOrigin:Float  'Touch drag fields. (for scroll events)
	
	'Widget managing elements
	Field Widgets:= New Stack<Widget>
	Field WidgetsByID:= New IntMap<Widget>  'For accessing widgets by ID
	Field childInput:PanelPointer
	
	'Flags
	Field __endlessX:Bool = True, __endlessY:Bool = True  'Uncap the XY boundaries
	Field __zLowerLimit:Float = 0.1, __zUpperLimit:Float = 3
	
	Const FRICTION:Float = 0.08  'Amount of friction to apply to scroll control
	Const csDist:Float = 42 'Square of the distance from origin to determine whether the user intends to click or scroll	
	
	Method New(x:Int, y:Int, w:Int, h:Int, Input:InputPointer)
		Super.New(x, y, w, h, Input)
		
		childInput = New PanelPointer(Input)
	End Method
	Method New(x:Int, y:Int, w:Int, h:Int, cw:Float, ch:Float, Input:InputPointer)
		Super.New(x, y, w, h, Input)
		Self.cw = cw; Self.ch = ch

		childInput = New PanelPointer(Input)
	End Method

	'Summary:  Permanently attaches a widget to this manager for control.  Overrides existing input with child input.
	Method Attach:Int(widget:Widget, id:Int = -1)
		widget.Input = childInput
	
		'To generate a unique ID, we must find a number that's unlikely to be repeated no matter how many widgets we add here.
		'Doing this in int32 space is difficult, so we comprimise by attempting to fill most of the values in the upper limit
		'of this space.  14 bits of data (not counting the sign bit) are allocated high and assigned to a random number, then
		'masked against the current stack size.  This should provide unique values for at least 100,000 widgets, while giving
		'only a 1-in-16382 chance of an auto ID collision if the stack size shrinks and stack length is repeated again.

		'All negative numbers (except for -1), and numbers from 0-$1FFFF are all valid ID's that can be manually assigned
		'with no chance of a collision by the auto-assignment.
				
		If id = -1 Then id = (Rnd(1, $3FFF) Shl 17) | Widgets.Length() 'Auto-assign a unique widget ID. Should support >100k widgets.
		
		Widgets.Push(widget)
		WidgetsByID.Add(id, widget)
		
		Return id
	End Method				
	
	Method MouseHit:Void()
		'First touch.  Set origin to this location.  Set the scroll origin for the first time, also.
		firstX = Input.x; firstY = Input.y
		xOrigin = Input.x; yOrigin = Input.y
	
		'Start checking to see whether this is a click or a scroll.
		'If the control is currently spinning with momentum, then don't process a click, just stop the control.
		'Otherwise, process a click.		
			If yMomentum = 0 And xMomentum = 0 Then clickStart = True
		
			yMomentum = 0; xMomentum = 0
			Scrolling = True
	End Method
	
	Method MouseDown:Void()
		holding = True
	End Method
	
	Method MouseUp:Void()
		holding = False
		
		'Put the first click origins into a galaxy far, far away. 
		firstX = -$FFFFFF; firstY = -$FFFFFF  'Prevents re-clicks from instantly stopping the scroller on the next poll.
		
		'Scrolling = False
	End Method	

	Method MouseClick:Void()
		If clickStart = True Then  'Clicked instead of dragged.  Do appropriate cell click behavior.
			clickStart = False
			xMomentum = 0
			yMomentum = 0
				
		End If
	End Method
		
	Method Poll:Void(xOffset:Float = 0, yOffset:Float = 0)
		'Before polling, let's make sure that the position of the cursor isn't too far away from the origin.
		'If it is, then we know to set clickStart FALSE before checking MouseClick(). This prevents a click
		'from being processed on the same frame the cursor input was first initiated.

		If UI.DistSq(firstX, firstY, Input.x, Input.y) > csDist Then clickStart = False		
					
		'This method performs the necessary polling of the object, as well as updating the scrolling/clickstate logic.
		Super.Poll()
		
		'Is the click+drag origin from this control?
		Local OriginallyFromHere:Bool = UI.WithinRect(firstX, firstY, x, y, w, h)
					
		xMomentum *= (1.0 - FRICTION)  'Apply friction
		yMomentum *= (1.0 - FRICTION)
		
		Local amtX:Float = Input.x - xOrigin 'Amount change from origin since last update
		Local amtY:Float = Input.y - yOrigin
		
		If holding and OriginallyFromHere Then 'drag
			cx += amtX 'Increment the offset.
			cy += amtY 'Increment the offset.
			If Abs(amtX) > Abs(xMomentum) Then xMomentum = amtX 'only add momentum if going faster than before.
			If Abs(amtY) > Abs(yMomentum) Then yMomentum = amtY

			If Sgn(amtX) <> 0 And Sgn(amtX) <> Sgn(xMomentum) Then xMomentum = amtX 'stops direction popping
			If Sgn(amtY) <> 0 And Sgn(amtY) <> Sgn(yMomentum) Then yMomentum = amtY
			xOrigin = Input.x 'update the origin for next update		
			yOrigin = Input.y
		End If
		
		If Input.Up Then Self.MouseUp()
		
		If holding = False Or (holding And Not OriginallyFromHere) Then  'no drag.  Slide with momentum.
			cx += xMomentum
			cy += yMomentum
		End If
		
		'Dink the momentums if they're below threshold. 
		
		If Abs(xMomentum) < 0.01 Then
			xMomentum = 0
			cx = Floor(cx + 0.4) 'round
		End If
		If Abs(yMomentum) < 0.01 Then
			yMomentum = 0
			cy = Floor(cy+0.4) 'round
		End If		

		'Dink the offset values and momentum if we hit the internal contents of the panel's limit.
		If __endlessX = False
			If cx > 0  'left
				cx = 0
				xMomentum = 0
			ElseIf cw > w And - cx > cw - w  'right
				cx = - (cw - w)
				xMomentum = 0
			ElseIf cw <= w  'no X scroll possible
				cx = 0
				xMomentum = 0
			End If
		End If
		If __endlessY = False
			If cy > 0  'top
				cy = 0
				yMomentum = 0
			ElseIf ch > h And - cy > ch - h  'bottom
				cy = - (ch - h)
				yMomentum = 0
			ElseIf ch <= h  'no Y scroll possible
				cy = 0
				yMomentum = 0				
			End If
		End If
				
				
		'Update the scrolling status.
		Scrolling = ( Not clickStart) And Not (xMomentum = 0 And yMomentum = 0)
		childInput.scrolling = Scrolling

		'Poll the child widgets.		
		If Enabled
			For Local o:Widget = EachIn Widgets				
				o.Poll(x + cx, y + cy)
			Next		
		End If
				
	End Method
	
	Method Render:Void(xOffset:Float = 0, yOffset:Float = 0)
		UI.PushScissor()
		UI.SetXformedScissor(x, y, w, h)

			PushMatrix()
			Translate(x + cx, y + cy)

				RenderContent(xOffset, yOffset)
						
			PopMatrix()

		UI.PopScissor()
	End Method
	
	'Summary:  Renders the content of the panel after setting the proper translation/scissor. Override this and call Super to render widgets.
	Method RenderContent:Void(xOffset:Float = 0, yOffset:Float = 0)
		'Render attached widgets
		If Enabled	
			For Local o:Widget = EachIn Widgets
				o.Render(xOffset, yOffset)
			Next
		End If
		'Note: You can call Super before or after your code, depending on where in the render order you want child widgets to render.
	End Method

	'Summary:  Returns the position of the scrollable area as a percentage of its bounds (for scrollbars). 
	Method PercentX:Float() Property
		If __endlessX Then Return - 1
		Return (-cx / (cw - w))
	End Method
	'Summary:  Returns the position of the scrollable area as a percentage of its bounds (for scrollbars). 
	Method PercentY:Float() Property
		If __endlessY Then Return - 1
		Return (-cy / (ch - h))
	End Method
End Class


'Summary:  Allows a Panel to override normal input if it's scrolling.
Class PanelPointer Implements InputPointer
	Field p:InputPointer

	Field scrolling:Bool
		
	Method New(prototype:InputPointer)
		p = prototype
	End Method
	
	Method x:Float() Property
		Return p.x
	End Method
	Method y:Float() Property
		Return p.y
	End Method

	Method Poll:Void()  
		'Nothing here.  Update the prototype instead.	
	End Method
	
	'No Set methods;  These properties are read-only
	Method Hit:Bool() Property
		If Not scrolling Then Return p.Hit()
	End Method
	Method Down:Bool() Property
		If Not scrolling Then Return p.Down()
	End Method
	Method Up:Bool() Property
		If Not scrolling Then Return p.Up()
	End Method	
End Class