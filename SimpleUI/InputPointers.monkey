' This file is for dealing with the types of input devices available across platforms.
' Some types of interfaces may need to be custom-coded for a solution, for example,
' Using multitouch, or adjusting for surface scaling.  In those cases, SimpleUI
' should not attempt to poll directly from a single input source.
' Therefore, the InputPointer interface is used to poll for input.  One example
' class implementing InputPointer is provided, but you should write your own
' for your game to deal with how your game handles input.
'    -Nobuyuki (nobu@subsoap.com)  25 Jun 2012

Import mojo

Interface InputPointer  'This is a generic wrapper for our human interface device.
	Method x:Float() Property
	Method y:Float() Property

	Method Poll:Void()  'Polls the input state
	Method Hit:Bool() Property '1st time hit 
	Method Down:Bool() Property 'Holding down
	Method Up:Bool() Property 'Unclicked / Lifted up
End Interface


' This class is provided as an example.  You may extend it to override individual functions,
' or simply write your own from scratch.
Class MousePointer implements InputPointer
Private
	Field Holding:Bool 'Used to implement MouseUp event
	Field _hit:Bool, _down:Bool, _up:Bool 
Public 
	Method x:Float() Property
		Return MouseX()
	End Method
	Method y:Float() Property
		Return MouseY()
	End Method

	Method Poll:Void()  'This method sets all of the properties to their internal values.
		'The reason all of our input states are properties is so they can be defined in the abstract interface.
		'When we call this method, we're telling all of its internal values to be set correctly.
		'This method should be called each frame before checking any value.
		
		If MouseHit(MOUSE_LEFT) > 0 Then 
			_hit = True  
		Else
			_hit = False 
		End If 		
		
		If MouseDown(MOUSE_LEFT) Then 
			Self.Holding = True
			_down = True 
		Else 'Not holding MouseDown
			_down = False 
			If Self.Holding = True Then  'Was holding last frame.  Do MouseUp 
				Self.Holding = False
				_up = True
			Else ; _up = False 
			End If 
		End If
			
	End Method
	
	'No Set methods;  These properties are read-only
	Method Hit:Bool() Property
'		If MouseHit(MOUSE_LEFT) > 0 then 
'			Self.Holding = True 
'			Return True 
'		End If 
'		Self.Holding = False 
'		Return False 
		Return _hit 
	End Method
	Method Down:Bool() Property
'		If MouseDown(MOUSE_LEFT)
'			Self.Holding = True 	
'			Return True 
'		End If
'		Self.Holding = False 
'		Return False 
		Return _down 
	End Method
	Method Up:Bool() Property
'		If Self.Holding And Not MouseDown(MOUSE_LEFT) Then 'The mouse was released
'			Self.Holding = False 
'			Print "Up"
'			Return True 
'		End If
'		Return False 
		Return _up 
	End Method
	
End Class
