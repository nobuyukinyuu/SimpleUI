Import mojo
Import InputPointers 
Import widget

'Summary:  A basic button class which many controls derive from.
Class PushButton Extends Widget
	Field hit:Bool 'Click event indicator
	Field down:Bool 'MouseDown event indicator
	Field up:Bool 'MouseUp event indicator
	
	Method New(x:Float, y:Float, w:Float, h:Float, Input:InputPointer)
		Super.New(x, y, w, h, Input)
	End Method

	Method Render:Void(xOffset:Float = 0, yOffset:Float = 0)
		If Visible 
			SetColor(128,128,192)
			If down Then SetColor(128, 192, 192)
	
			DrawRect(x + xOffset, y + yOffset, w, h)
			SetColor(255, 255, 255)
			DrawText(Self.Text, (x + w / 2) + xOffset, (y + h / 2) + yOffset, 0.5, 0.5)
		End If
	End Method

	Method Poll:Void(xOffset:Float = 0, yOffset:Float = 0)
		hit = False
		down = False
		up = False
		Super.Poll(xOffset, yOffset)
	End Method	

	Method MouseClick:Void()
		Super.MouseClick()
		If Visible And Enabled Then hit = True
	End Method
	
	Method MouseDown:Void()
		Super.MouseDown()
		If Visible And Enabled Then down = True
	End Method
	
	Method MouseUp:Void()
		Super.MouseUp()
		If Visible and Enabled Then up = True
	End Method
End Class
