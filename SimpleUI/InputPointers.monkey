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

'Summary:  Provides a mouse pointer which is aware of the current global scaling matrix.
Class ScaleAwarePointer Extends MousePointer
	Method x:Float() Property
		Local m:Float[] = GetMatrix()
		Return (MouseX() -m[4]) / m[0]
	End Method
	Method y:Float() Property
		Local m:Float[] = GetMatrix()
		Return (MouseY() -m[5]) / m[3]
	End Method
End Class


'Summary:  For multitouch-requiring components.  Extend this if you need to.  (Work in progress 21 Dec 2013)
Class MultiTouchPointer Implements InputPointer
Private
	Field Holding:Bool[16] 'Used to implement MouseUp event
	Field _hit:Bool[16], _down:Bool[16], _up:Bool[16]
Public

	'Single touch methods (InputPointer compatible)
	Method x:Float() Property
		Return TouchX()
	End Method
	Method y:Float() Property
		Return TouchY()
	End Method
	
	'Multitouch methods.
	Method x:Float(finger:Int)
		Return TouchX(finger)
	End Method
	Method y:Float(finger:Int)
		Return TouchY(finger)
	End Method
	
	Method Poll:Void()		
		For Local f:Int = 0 Until 16
			If TouchHit(f) > 0 Then
				_hit[f] = True
			Else
				_hit[f] = False
			End If 		
			
			If TouchDown(f) Then
				Self.Holding[f] = True
				_down[f] = True
			Else 'Not holding Down
				_down[f] = False
				If Self.Holding[f] = True Then  'Was holding last frame.  Do Up
					Self.Holding[f] = False
					_up[f] = True
				Else; _up[f] = False
				End If 
			End If
			
		Next
			
	End Method

	Method Hit:Bool()
		Return _hit[0]
	End Method
	Method Down:Bool()
		Return _down[0]
	End Method
	Method Up:Bool()
		Return _up[0]
	End Method
	
	'Multitouch methods	
	Method Hit:Bool(finger:Int)
		Return _hit[finger]
	End Method
	Method Down:Bool(finger:Int)
		Return _down[finger]
	End Method
	Method Up:Bool(finger:Int)
		Return _up[finger]
	End Method

	'Summary:  Returns how many fingers are being held down.
	Method Fingers:Int()
		Local result:Int
		For Local i:Int = 0 Until 16
			If _down[i] Then result += 1
		Next
		
		Return result
	End Method
End Class

'Summary:  A multitouch pointer which is aware of the matrix scale.
Class ScaleAwareMultiTouchPointer Extends MultiTouchPointer
	Method x:Float() Property
		Local m:Float[] = GetMatrix()
		Return (TouchX() -m[4]) / m[0]
	End Method
	Method y:Float() Property
		Local m:Float[] = GetMatrix()
		Return (TouchY() -m[5]) / m[3]
	End Method
	
	Method x:Float(finger:Int)
		Local m:Float[] = GetMatrix()
		Return (TouchX(finger) - m[4]) / m[0]
	End Method
	Method y:Float(finger:Int)
		Local m:Float[] = GetMatrix()
		Return (TouchY(finger) - m[5]) / m[3]
	End Method
End Class