Strict

Import mojo

'This imports the most basic things needed to get started.
Import SimpleUI.common
'The following are not included in the common init, add them as necessary.
Import SimpleUI.widgetManager
Import SimpleUI.Scrollers

Function Main:Int()
	New Game()
	Return 0
End Function

Class Game Extends App
	Field status:String = "Better example coming soon..."

	'This is the cursor we use for the example. It -should- support scaled screens...
	Field Cursor:= New ScaledTouchPointer()
	'This is a widget manager.  For lazy people, you can poll/render batches of widgets at once!
	Field widgets:WidgetManager
	'Some pushbuttons.  You'll want to extend these to provide your own functionality.
	Field button:PushButton[3]
	'A scroller.
	Field scroll:EndlessScroller
	
	Method OnCreate:Int()
		SetUpdateRate 60
				
		'Set up the widget manager to utilize our global InputPointer.
		widgets = New WidgetManager(Cursor)
		
		'Initialize the buttons.
		For Local i:Int = 0 Until 3
			button[i] = New PushButton(16, 32 + i * 48, 96, 32, Cursor)
			button[i].Text = "Button " + i
			
			widgets.Attach(button[i])
		Next

		'Set up the scroller.
		scroll = New EndlessScroller(320, 32, 256, 320, 10, Cursor, 48)
		scroll.Items = scroll.Items.Resize(10)
		For Local i:Int = 0 Until 10
			Local c:= New ExampleCell()
			c.w = 256
			c.h = 48
			c.text = "Cell " + i
			c.r = Rnd(255)
			c.g = Rnd(255)
			c.b = Rnd(255)
			
			scroll.Items[i] = c
		Next
		widgets.Attach(scroll)
		
		Return 0
	End Method
	
	Method OnUpdate:Int()				
		If KeyHit(KEY_ESCAPE) or KeyHit(KEY_CLOSE) or KeyHit(KEY_BACK) Then Error("")

		'In order for anything to detect, we must poll the InputPointer at the beginning of each frame.
		Cursor.Poll()

		'Tell our widget manager "Okay, let's poll our widgets for input."		
		widgets.PollAll()

		'Now let's check that input.		
		For Local i:Int = 0 Until 3
			If button[i].hit
				status = "Button " + i + " hit."
			End If			
		Next

		Return 0		
	End Method
	
	Method OnRender:Int()
		Cls(0, 16, 64)

		widgets.RenderAll()
				
		SetAlpha(0.4)
		DrawCircle(Cursor.x, Cursor.y, 8)
		SetAlpha(1)
		
		Local m:Float[] = GetMatrix()
		DrawText(status, 0, 0)
		Return 0
	End Method
End Class

'Summary: Class providing a SimpleUI InputPointer for an AutoScaled touchscreen.  No multitouch.
Class ScaledTouchPointer Extends MousePointer
	Method x:Float() Property
		Return dTouchX()
	End Method
	Method y:Float() Property
		Return dTouchY()
	End Method
	
'Derived multitouch positions
Function dTouchX:Int(index:Int = 0)
	Local m:Float[] = GetMatrix()
		Return TouchX(index) / m[0] - (m[4] / m[0])
End Function

Function dTouchY:Int(index:Int=0)
	Local m:Float[] = GetMatrix()
		Return TouchY(index) / m[3] - (m[5] / m[3])
End Function
End Class


