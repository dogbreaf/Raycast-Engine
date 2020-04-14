''
''	uitk textinput
''	by Mishka
''
''	this code works somehow but I feel like I did something wrong, I'm so sorry
''

#define uiTextinputEditColor	rgb(255,240,100)
#define uiTextinputColor	rgb(255,255,255)

type uiTextinput extends uiElement
	declare constructor ()
	declare sub update() override
end type

constructor uiTextinput()
	this.box.style = concave_embossed
	this.box.color.value = rgb(255,255,255)
end constructor

sub uiTextinput.update()
	if this.onClick then
		' Make it active (accepts input) when clicked on
		this.active = true
	elseif this.context->mouseBtn1 then
		' Make it inactive when anything else is clicked
		this.active = false
	endif
	
	if active then
		' Change to active color
		this.box.color.value = uiTextinputColor
		
		' always update the graphic if the text area is active
		this.refresh = true

		if this.context->keybuffer = Chr(8) then
			' Backspace key
			this.value = left( this.value, len(this.value)-1 )
		else
			this.value += this.context->keybuffer
		endif
		
		' box text equal to value
		this.box.text = this.value
	else
		' Change to default color
		this.box.color.value = uiDefaultColor
		this.refresh = true
	endif
end sub

