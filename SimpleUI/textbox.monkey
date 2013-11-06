Import ui
Import InputPointers
Import widget

Class TextBox Extends Widget
	Field HasFocus:Bool
	Field skin:TextBoxSkin = New DefaultTextboxSkin()
	Field chars:= New Stack<Int>  'Character input queue on last Poll()
	
	Field hit:Bool  'Activated for one frame when the control receives focus.
	
	Method New(x:Float, y:Float, w:Float, h:Float, Input:InputPointer)
		Super.New(x, y, w, h, Input)
	End Method

	Method New(x:Float, y:Float, w:Float, h:Float, skin:TextBoxSkin, Input:InputPointer)
		Super.New(x, y, w, h, Input)
		Self.skin = skin
	End Method

				
	Method Poll:Void(xOffset:Float = 0, yOffset:Float = 0)
		Super.Poll(xOffset, yOffset)
		
		Self.hit = False
		
		Local inWidget:Bool = UI.WithinRect(Input.x, Input.y, Self.x + xOffset, Self.y + yOffset, Self.w, Self.h)
		
		If Input.Hit And inWidget Then
			If HasFocus = False Then GotFocus()
			HasFocus = True	
		ElseIf Input.Hit And inWidget = False Then
			If HasFocus = True Then LostFocus()
			HasFocus = False
		ElseIf KeyHit(KEY_BACK) And HasFocus
			LostFocus()
			HasFocus = False
		End If
		
		
		If HasFocus
			'Capture input events.  First, clear the char queue
			chars.Clear()
			
			'Repopulate the char queue.
			Local char:Int
			Repeat
				char = GetChar()
				chars.Push(char)
			Until char = 0
			
			'Now, process input events.
			For Local c:Int = EachIn chars
				If c > 16 And c < 256 And c <> 8 Then
					Text += String.FromChar(c)
				ElseIf c = 8 'Backspace
					Text = Text[0 .. - 1]
				End If
				If c > 0 Then KeyPress(c)
			Next
			
		End If
	End Method

	Method KeyPress:Void(char:Int)
		'Put key press event stuff here when extending the class.
	End Method
		
	Method GotFocus:Void()
		'Put specific stuff here when extending the class
		
		#If TARGET="android" or TARGET="ios"
			EnableKeyboard()
		#End
		
		Self.hit = True
	End Method
	
	Method LostFocus:Void()
		'Put specific stuff here when extending the class

		#If TARGET="android" or TARGET="ios"
			DisableKeyboard()
		#End
	End Method
	
	Method Render:Void(xOffset:Float = 0, yOffset:Float = 0)
		skin.Render(Self, xOffset, yOffset)
	End Method
End Class

Interface TextBoxSkin
	Method Render:Void(caller:TextBox, x:Float = 0, y:Float = 0)
End Interface

Class DefaultTextboxSkin Implements TextBoxSkin
	Method Render:Void(caller:TextBox, x:Float = 0, y:Float = 0)
		'Draw bg
		If caller.HasFocus Then
			SetAlpha(0.1)
			DrawRect(caller.x + x, caller.y + y, caller.w, caller.h)
			SetAlpha(1)
		End If
	
		'Draw text
		DrawText(caller.Text, caller.x + x + 2, caller.y + y + 2)
		
		'Draw box
		DrawLine(caller.x + x, caller.y + y, caller.x + x, caller.y + y + caller.h)
		DrawLine(caller.x + x, caller.y + y, caller.x + x + caller.w, caller.y + y)
		DrawLine(caller.x + x + caller.w + y, caller.y + caller.h, caller.x + x, caller.y + y + caller.h)
		DrawLine(caller.x + x + caller.w + y, caller.y + caller.h, caller.x + x + caller.w, caller.y + y)
	End Method
End Class