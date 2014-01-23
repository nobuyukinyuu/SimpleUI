Import mojo
Import InputPointers
Import ui

'Summary:  This is the base class which all SimpleUI components derive from.
Class Widget
  Private
	Field Holding:Bool 'If holding down in the widget 
		
  Public
  	Field id:Int  'For tagging a widget for the widget manager.  Optional.
	 
	Field x:Float, y:Float  'Location
	Field w:Float=32, h:Float=32  'Size
	Field Input:InputPointer 
	Field Text:String
	Field Visible:Bool = True
	Field Enabled:Bool = True

	Method New(x:Float, y:Float, w:Float, h:Float)
		Self.x=x ; Self.y=y ; Self.w=w ; Self.h=h
		
		Input = New MousePointer()
	End Method

	Method New(x:Float, y:Float, w:Float, h:Float, input:InputPointer)
		Self.x=x ; Self.y=y ; Self.w=w ; Self.h=h
		
		Self.Input = input 
	End Method

	'Summary:  This function polls the widget to see if it should execute any methods. Don't call if not Visible.		
	Method Poll:Void(xOffset:Float = 0, yOffset:Float = 0)
		Local inWidget:Bool = UI.WithinRect(Input.x, Input.y, Self.x + xOffset, Self.y + yOffset, Self.w, Self.h)

		'Check input to do things.  In derived classes, you can poll the InputPointer before calling Super here.
		If inWidget Then 
			Self.MouseOver()		

			If Input.Hit Then 
				Holding = True
				Self.MouseHit()
			End If 

			If Input.Down Then Self.MouseDown()

			If Input.Up Then 'User releasing input over this control.
				Self.MouseUp()
				'Check to see if the widget was tapped earlier.  If so, activate the Click event.
				If Holding = True Then 
					Self.MouseClick()
					Holding = False
				End If 
			End If 

		End If 
		
		If Not Input.Down Then Holding = False  'Deactivate Holding whether or not we're in the control 
	End Method
		
	Method MouseOver:Void()
		'Put Hover event code in here when extending the class
	End Method
	
	Method MouseDown:Void()
		'Put MouseDown event code in here when extending the class
	End Method
	
	Method MouseHit:Void()
		'Put MouseHit event code in here when extending the class
	End Method
	
	Method MouseUp:Void()
		'Put MouseUp event code in here when extending the class
	End Method 
	
	Method MouseClick:Void()
		'Put event code in here when extending the class for when a control was clicked
	End Method
	
	Method Render:Void(xOffset:Float = 0, yOffset:Float = 0)
		'Overload me!
	End Method
End Class
