' Scrollers provide a means to scroll lists/panels of data.  They are roughly equivalent to a ListBox 
' in other UI toolkits, although the default Scroller type loops endlessly.  The interface for Scrollers
' is optimized for touch-based input.
'										-Nobuyuki (nobu@subsoap.com)  8 July 2013.

Import mojo
Import ui
Import InputPointers
Import widget

Class Scroller Extends EndlessScroller
	Field Slack:Float  'How much did the user attempt to scroll past the border of this control?
	Field Snapper:SlackDrawer
	
	'Summary:  Initializes a new Scroller with numElements items.
	Method New(x:Int, y:Int, w:Int, h:Int, numElements:Int, Input:InputPointer, cellHeight:Float = 32)
		Super.New(x, y, w, h, numElements, Input, cellHeight)
		Snapper = New ExampleSlackDrawer(Self)
		__loopCells = False
	End Method
	
	'Summary: Snaps the input offset to a sane one based on this control's sizes
	Method BorderSnap:Float(offset:Float)
		Local contentHeight:Float = Items.Length * cellHeight
		Return Clamp(offset, Min(0.0, -contentHeight + h), 0.0)
	End Method

	Method Render:Void(xOffset:Float = 0, yOffset:Float = 0)
		Snapper.RenderStart()
		Super.Render(xOffset, yOffset)
		Snapper.RenderEnd()
	End Method
	
	Method Poll:Void(xOffset:Float = 0, yOffset:Float = 0)
		Super.Poll()
		
		If Slack <> 0 And Input.Down = False Then Slack = Slack * 0.98   'Reduce slack per frame
		
		Local slack:Float = cOffset
		cOffset = BorderSnap(cOffset)
		Slack = slack - cOffset
	End Method
	
End Class

Class EndlessScroller Extends Widget
  'Private
  'WARNING:  THESE VARIABLES SHOULD BE PRIVATE, BUT THEY'VE BEEN MADE PUBLIC TO ALLOW SUBCLASSING.
  '          IN THE FUTURE, THESE VARIABLES SHOULD BE SET USING THE 'Protected' DIRECTIVE, ONCE
  '          MONKEY SUPPORTS IT.
  
  	Field startPos:Float 'The first element to draw in the control. Important for determining clicks, also.
	Field drawOffset:Float 'The actual y offset from which the drawing routines start drawing cells.
  
	Field holding:Bool 'Is the user holding down the mouse button?
	Field clickStart:Bool 'Is the user holding down the button for a (non-drag) click?
	
	'Options and flags
	Field __scissorCells:Bool = True  'Forces cells to render only within their borders. This is necessary if cells draw outside their borders. 
	Field __loopCells:Bool = True     'If the number of drawn cells is shorter than scroller's bounds, loopback to 0 and fill the remainder of the space.
	
  Public
	'The origin and clip region of this control are determined in Super by x, y, w, and h.
	'Field x:Int, y:Int, w:Int, h:Int
	
	Field firstX:Float, firstY:Float 'Persistent touch origin.
	Field cMomentum:Float, cOffset:Float, cOrigin:Float  'Touch drag fields. (for scroll events)
	
	Const FRICTION:Float = 0.08  'Amount of friction to apply to scroll control
	Const csDist:Float = 42 'The square of the distance from origin to determine whether the user intends to click or scroll; precalculated for speed
	
	Field Scrolling:Bool 'Is the control scrolling?
	
	Field Items:ScrollerCell[]  'Cells in this scroller.
	Field cellHeight:Float  'Cell height, for determining hitbox and element positioning.
	Field cellsToDraw:Int  'Cells to draw in the drawing operation.
	
	Field IndexChanged:Bool = False 'Changes to TRUE for 1 frame if the selected index changes.
	Field SelectedIndex:Int = -1 'The index of the cell clicked.
	
	'Summary:  Initializes a new Scroller with numElements items.
	Method New(x:Int, y:Int, w:Int, h:Int, numElements:Int, Input:InputPointer, cellHeight:Float = 32)
		Super.New(x, y, w, h, Input)

		Items = Items.Resize(numElements)
		
		Self.cellHeight = cellHeight
		cellsToDraw = Ceil(h / cellHeight)
	End Method

	Method AddItem:Void(item:ScrollerCell)
		Items = Items.Resize(Items.Length + 1)  'Add one
		Items[Items.Length - 1] = item
	End Method
	
	'Summary:  Determines which cell is at the current cursor position.
	Method CellAtCursorPosition:Int(Cursor:InputPointer)
		Local i:Float = ( (Cursor.y - y + (cellHeight - drawOffset)) / h) * (h / cellHeight)
		i = Floor(i) - 1
		Local index:Int = i + startPos  'this value is the "true" element position we use.

		'If the list isn't supposed to loop, return an -1 if clicked in the scroller bounds but not on a cell.
		If __loopCells = False And index >= Items.Length Then Return - 1
		
		'Now, let's clamp index to the correct value.
		'While index > Items.Length - 1; index -= Items.Length; Wend
		index = CycleDown(index, Items.Length)
		Return index
	End Method

	'Summary:  Determines the click position relative to the cell at the cursor position.	
	Method ClickPosition:Float[] (Cursor:InputPointer)
		Local i:Float = (Cursor.y - y + (cellHeight - drawOffset)) Mod cellHeight
		Return[Cursor.x - Self.x, i]
	End Method
	
	'Summary:  Internal function to cycle down a value out of range.
	Method CycleDown:Int(index:Int, maxvalue:Int)
		If maxvalue <= 0 Then Return 0  'stop an infinite loop
		While index >= maxvalue; index -= maxvalue; Wend
		Return index
	End Method
	
	'NOTE:  TODO:  Implement xOffset/yOffset properly here. They were added to conform with Widget
	Method Render:Void(xOffset:Float = 0, yOffset:Float = 0)
		'Sanity check
		If Items.Length < 1 Then Return
		If Visible = False Then Return
		
		'Set the clipping rectangle for the widget's bounds if we're not scissoring on a cell-by-cell basis.
		If Not __scissorCells
			UI.PushScissor()
			UI.SetXformedScissor(x, y, w, h)
		End If		
				
		'We need to figure out which elements we need to draw in the clip rect. 
		'First, we should determine the content size.
		Local contentHeight:Int = Items.Length * cellHeight
				
		'Now let's determine the first and last element to draw within the content.
		'The start position in the content depends on whether the Offset is positive or negative. StartPos will always be > 0.
		'The end position is just startPos + cellsToDraw.  If the value leaks over the content size, we'll
		'catch that later by subtracting content's index size.
		'NOTE:  These positions assume a sane offset value
		'Local startPos:Float   'This will be floored later.

		
		Local SaneOffset:Float = GetSaneOffset(cOffset, contentHeight, -contentHeight)
		
		If Sgn(SaneOffset) <= 0 'Offset is 0 or negative. Set startPos normally.
			startPos = (-SaneOffset) / cellHeight
		ElseIf Sgn(SaneOffset) >= 1  'Offset is positive.  Set startPos by subtracting offset from contentHeight.
			startPos = (contentHeight - SaneOffset) / cellHeight
		End If
		
		'Let's get the actual offset we're gonna start drawing from.  Since we're going to draw h/cellHeight+1 elements, our offset
		'should always be between 0 and -cellHeight.  To do this, we use modulus.  Once again, the number we need depends on the 
		'sign of the offset.
		'Local drawOffset:Float
		
		If Sgn(cOffset) > 0 'positive offset means we need to subtract cellHeight to get a negative drawOffset.
			drawOffset = (cellHeight - (cOffset mod cellHeight)) * -1
		Else 'a negative cOffset provides the range we want using simple modulus.
			drawOffset = cOffset Mod cellHeight
		End If
		If drawOffset = -cellHeight Then drawOffset = 0  'Fudge factor
		
		
		For Local i:Int = 0 To cellsToDraw  'Draw only the cells which are visible.
			If __loopCells = False  'Check to see if looping is disabled, and only draw the original cells.
				If Sgn(cOffset) > 0
					If i + startPos < Items.Length Then Continue
					If i + startPos > (Items.Length) * 2 Then Continue
				ElseIf Sgn(cOffset) = 0  'Do normal clamping.
					If i + startPos > Items.Length - 1 Then Continue
				Else
					If i + startPos > Items.Length Then Continue
				End If
			End If
		
			Local index:Int = i + startPos  'this value is the "true" element position we use.
			'While index > Items.Length - 1; index -= Items.Length; Wend   'Cycle the element within valid range.
			index = CycleDown(index, Items.Length)

			
			'Before Drawing the cells, Calculate the clip rectangle for them if specified.
			If __scissorCells Then
				Local cr:Float[] =[x, y + drawOffset + (i * cellHeight), w, cellHeight]
				'Clamp a cell partially going off the top of the widget
				If cr[1] < y Then
					cr[3] -= (y - cr[1])  'Reduce height of clip rect
					cr[1] = y  'set top of clip rect to top of widget.
				End If

				'Clamp a cell partially going off the bottom of the widget
				If cr[1] + cellHeight > y + h Then
					cr[3] = ( (y + h) - cr[1]) 'Reduce height of clip rect
				End If
				
				'Set the cell's scissor region.
				UI.PushScissor()
				UI.SetXformedScissor(cr[0], cr[1], cr[2], cr[3])
			End If
			
			'Draw the cell.
			If Items[index] <> Null Then Items[index].Draw(x, y + drawOffset + (i * cellHeight))
			
			'Reset the clipping rectangle.
			UI.PopScissor()
		Next

		'Reset the clipping rectangle for the widget bounds.
		If Not __scissorCells Then UI.PopScissor()
	End Method
	
	Method GetSaneOffset:Float(offset:Float, range:Float, startPoint = 0)
		'This function returns a sane drawing offset within the total items' size from a raw offset to a value between startPoint and range.
		Local returnValue:Float = offset 
		While returnValue > range ; returnValue -= range ; Wend 
		While returnValue < startPoint; returnValue += range; Wend
		Return returnValue 
	End Method
	
	Method MouseHit:Void()
		'First touch.  Set origin to this location.  Set the scroll origin for the first time, also.
		firstX = Input.x; firstY = Input.y
		cOrigin = Input.y
	
		'Start checking to see whether this is a click or a scroll.
		'If the control is currently spinning with momentum, then don't process a click, just stop the control.
		'Otherwise, process a click.		
			If cMomentum = 0 Then clickStart = True
		
			cMomentum = 0
			Scrolling = True
	End Method
	
	Method MouseDown:Void()
		holding = True
	End Method
	
	Method MouseUp:Void()
		holding = False
		
		firstX = -9999; firstY = -9999
		
		'Scrolling = False
	End Method
	
	Method MouseClick:Void()
		If clickStart = True Then  'Clicked instead of dragged.  Do appropriate cell click behavior.
			clickStart = False
			cMomentum = 0

			Local cell:Int = CellAtCursorPosition(Input)	
			
			'Don't process a click if the index is out of range.
			If cell >= Items.Length or cell < - 1 Then Return
			If SelectedIndex >= Items.Length Then Return
						
			'Deselect the previously selected index.
			If SelectedIndex >= 0 Then
				If Items[SelectedIndex] = Null Then Return  'Don't process a click if there's nothing here.
				Items[SelectedIndex].Selected = False				
			End If

			'If cell is -1 then this is probably a non-looping scroller click.  Deselect the previously selected index.
			If cell = -1
				SelectedIndex = -1
				Return
			End If			
						
			'Update the selected index.
			SelectedIndex = cell
			If Items[SelectedIndex] <> Null Then Items[SelectedIndex].Selected = True

			'Process the click event in the cell and indicate the index has changed.
			Local pos:Float[] = ClickPosition(Input)
			If Items[SelectedIndex] <> Null Then Items[SelectedIndex].Click(pos[0], pos[1])
			IndexChanged = True
		End If
	End Method
	
	'NOTE:  TODO:  Implement xOffset/yOffset properly here. They were added to conform with Widget
	Method Poll:Void(xOffset:Float = 0, yOffset:Float = 0)
		'Before polling, let's make sure that the position of the cursor isn't too far away from the origin.
		'If it is, then we know to set clickStart FALSE before checking MouseClick(). This prevents a click
		'from being processed on the same frame the cursor input was first initiated.

		If UI.DistSq(firstX, firstY, Input.x, Input.y) > csDist Then clickStart = False
		
		'Let's also reset the IndexChanged value of the control from the last loop.
		IndexChanged = False
	
		'This method performs the necessary polling of the object, as well as updating the scrolling/clickstate logic.
		Super.Poll()
		
		'Is the click+drag origin from this control?
		Local OriginallyFromHere:Bool = UI.WithinRect(firstX, firstY, x, y, w, h)
					
		cMomentum *= (1.0 - FRICTION)  'Apply friction
		
		Local amt:Float = Input.y - cOrigin 'Amount change from origin since last update
		
		If holding and OriginallyFromHere Then 'drag
			cOffset += amt 'Increment the offset.
			if Abs(amt) > Abs(cMomentum) Then cMomentum = amt 'only add momentum if going faster than before.
			if Sgn(amt) <> 0 And Sgn(amt) <> Sgn(cMomentum) Then cMomentum = amt 'stops direction popping
			cOrigin = Input.y 'update the origin for next update		
		End If
		
		If Input.Up Then Self.MouseUp()
		
		If holding = False Or (holding And Not OriginallyFromHere) Then  'no drag.  Slide with momentum.
			cOffset += cMomentum
		End If
		
		if Abs(cMomentum) < 0.01 Then 'Reset the control
			cMomentum = 0
			cOffset = Floor(cOffset+0.4) 'round
			Scrolling = False
			
			'Put cOffset back in a sane place
			cOffset = GetSaneOffset(cOffset, cellHeight * Items.Length, -cellHeight * Items.Length)
		End If
	End Method
	
End Class

'Summary:  This interface is provided to display and handle clicks within a Scroller's cell.
Interface ScrollerCell
	'Property Methods are defined here to enforce their existence in implementing classes.
	Method Selected:Bool() Property  'Is this cell the selected one in the list?
	Method Selected:Void(value:Bool) Property

	Method Draw:Void(xOffset:Float, yOffset:Float)
	Method Click:Void(xOffset:Float = -1, yOffset:Float = -1)
End Interface

Class ExampleCell Implements ScrollerCell
  Private
	Field timer:Int
	Field _selected:Bool
  Public
	Field x:Float, y:Float, w:Float, h:Float
	Field r:Int, g:Int, b:Int
	Field text:String
	Field lastX:Float = -1, lastY:Float = -1
	
	Method Selected:Bool() Property
		Return _selected
	End Method

	Method Selected:Void(value:Bool) Property
		_selected = value
	End Method
		
	Method Draw:Void(xOffset:Float, yOffset:Float)
		SetAlpha(0.6)
		SetColor(r, g, b)

		If timer > 0 Then
			timer -= 1
			SetAlpha(1)
		End If

		DrawRect(xOffset, yOffset, w, h)
		SetColor(255, 255, 255)
		DrawText(text, x + xOffset, y + yOffset)

		SetAlpha(1)
		If _selected = True Then
			DrawCircle(xOffset + (w - h / 2), yOffset + h / 2, h / 3)
		
			If lastX > 0 Then DrawLine(xOffset + lastX, yOffset, xOffset + lastX, yOffset + h)
			If lastY > 0 Then DrawLine(xOffset, yOffset + lastY, xOffset + w, yOffset + lastY)
			SetAlpha(0.5); DrawText(lastX + "," + lastY, lastX + xOffset, lastY + yOffset)
			SetAlpha(1)
		End If
	End Method
	
	Method Click:Void(xOffset:Float = -1, yOffset:Float = -1)
		timer = 10
		If xOffset <> - 1 Then lastX = xOffset
		If yOffset <> - 1 Then lastY = yOffset
	End Method
End Class

'Summary:  This interface is provided to provide draw routines for bordered Scrollers when the user drags past the limit.
Interface SlackDrawer
	'Property Methods are defined here to enforce their existence in implementing classes.
	Method Horizontal:Bool() Property  'Is the parent control Horizontal?
	Method Horizontal:Void(value:Bool) Property

	Method New(parent:Scroller)  'Provides the parent for this control
	Method RenderStart:Void()  'Done at beginning of Render()
	Method RenderEnd:Void()    'Done at the end of Render()
End Interface

'Summary:  This example provides a simple snap effect when the user drags past the scroller limit.
Class ExampleSlackDrawer Implements SlackDrawer
  Private
	Field _horizontal:Bool
  Public
	Field p:Scroller
	
	Method New(parent:Scroller)
		p = parent
	End Method
	
	'Satisfies SlackDrawer interface requirement
	Method Horizontal:Bool() Property
		Return _horizontal
	End Method
	Method Horizontal:Void(value:Bool) Property
		_horizontal = value
	End Method

	
	Method RenderStart:Void()
		p.cOffset += (p.Slack * 0.5)
	End Method
	
	Method RenderEnd:Void()
		p.cOffset -= (p.Slack * 0.5)
	End Method
	
End Class