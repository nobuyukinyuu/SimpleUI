'This imports the most basic things needed to get started.
Import SimpleUI.common
'The following are not included in the common init, add them as necessary.
Import SimpleUI.widgetManager
Import SimpleUI.unpacker

Import os

Function Main:Int()
	New Game()
	Return 0
End Function

Class Game Extends App
	Field Cursor:= New ScaleAwarePointer()

	Field btns:WidgetManager
	Field newDoc:PushButton
	Field load:PushButton
	Field save:PushButton
	
	Field originX, originY
	Field destX, destY
	
	Field rects:= New Stack<Rect>
	
	Field testLoader:WidgetManager
	
	Method OnCreate:Int()
		SetUpdateRate 60

		
		newDoc = New PushButton(4, 4, 64, 24, Cursor)
		newDoc.Text = "New"
		load = New PushButton(76, 4, 64, 24, Cursor)
		load.Text = "Load"
		save = New PushButton(148, 4, 64, 24, Cursor)
		save.Text = "Save"
		
		btns = New WidgetManager(Cursor)
		btns.Attach(newDoc)
		btns.Attach(load)
		btns.Attach(save)
		
		Local get:Int[] = GetDate()
		Seed = get[6] + get[5] + get[4] * (Millisecs() +1)
		Print Seed
		
		Unpacker.Init()
		testLoader = New WidgetManager(Cursor)
	End Method
	
	Method OnUpdate:Int()
		Cursor.Poll()
	
		If Cursor.Hit Then
			originX = Cursor.x
			originY = Cursor.y
			destX = Cursor.x + 2
			destY = Cursor.y + 2
		ElseIf Cursor.Down
			destX = Cursor.x
			destY = Cursor.y
			
		ElseIf Cursor.Up
			Local w:Float = destX - originX
			Local h:Float = destY - originY
			If w > 2 And h > 2 Then rects.Push(New Rect(originX, originY, w, h, GenName(Rnd(2, 5))))
		End If
		
		btns.PollAll()
		
		
		If newDoc.hit Then
			rects.Clear()
			testLoader = New WidgetManager(Cursor)
		End If
		If save.hit Then
			SaveState(PackAll())
			Print "Saved."
		End If
		
		If load.hit
			rects.Clear()
			testLoader = Unpacker.UnpackForm(LoadState(), Cursor)
			Print "Loaded."
		End If

		testLoader.PollAll()
	End Method
	
	Method OnRender:Int()
		Cls()

		For Local i:Int = 0 Until rects.Length
			Local o:Rect = rects.Get(i)
			SetColor(128, 0, 0)
			o.Draw()
			SetColor(255, 255, 255)
			DrawText(i, o.x, o.y)
		Next
		
		If Cursor.Down
			Local w:Float = destX - originX
			Local h:Float = destY - originY
			SetAlpha(0.5)
			DrawRect(originX, originY, w, h)
			SetAlpha(1)
		End If
				
		btns.RenderAll()
		testLoader.RenderAll()
		
	End Method
	
	Method GenName:String(syllables:Int)
		Local vowel:String[] =["a", "e", "i", "o", "u"]
		Local cons:String[] =["b", "d", "g", "k", "t", "t", "s", "s", "r", "r", "n", "j", "h", "p"]
		
		Local size:Int = syllables * 2
		If Int(Rnd(5)) = 0 Then size += 1  'end consonant
		
		Local parts:String[size]

		For Local i:Int = 0 Until parts.Length
			If i & 1 = 0 Then 'Consonant
				parts[i] = cons[Rnd(cons.Length)]
			Else		
				Select Int(Rnd(5))
					Case 0  'Double vowel
						parts[i] = vowel[Rnd(vowel.Length)] + vowel[Rnd(vowel.Length)]
					Default  'Single vowel
						parts[i] = vowel[Rnd(vowel.Length)]
				End Select
			End If
		Next
		
		Local out:String
		Return out.Join(parts)
	End Method
	
	Method PackAll:String()
		Local o:JsonObject = New JsonObject()
		Local wStack:= New Stack<JsonValue>  'Stack of widgets to be converted to jsonArray later

		For Local i:Int = 0 Until rects.Length
			wStack.Push(Pack(rects.Get(i), i))
		Next
		o.Set("Widgets", New JsonArray(wStack.ToArray()))
		
		Print o.ToJson()
		Return o.ToJson()		
	End Method
	Method Pack:JsonObject(w:Rect, salt:Int)
		Local o:= New JsonObject()
		o.SetInt("id", UI.GenerateID(salt))
		o.SetString("Text", w.name)
		o.SetString("type", "pushbutton")

		o.SetFloat("x", w.x)
		o.SetFloat("y", w.y)
		o.SetFloat("w", w.w)
		o.SetFloat("h", w.h)
		
		o.SetBool("Enabled", True)
		o.SetBool("Visible", True)

		Return o
	End Method
End Class

Class Rect
	Field x:Float, y:Float, w:Float, h:Float
	Field name:String
	
	Method New(X:Float, Y:Float, W:Float, H:Float, Name:String = "")
		x = X; y = Y; w = W; h = H
		name = Name
	End Method
	
	Method Draw:Void()
		DrawRect(x, y, w, h)
		SetColor(255, 255, 0)
		DrawText(name, x + w / 2, y + h / 2, 0.5, 0.5)
		SetColor(255, 255, 255)
	End Method
End Class
