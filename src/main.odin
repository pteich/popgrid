package main

import "core:c"
import "core:fmt"
import "core:math/rand"
import "core:time"
import "vendor:raylib"

SCREEN_WIDTH :: 500
SCREEN_HEIGHT :: 500
bkg :: raylib.Color{232, 237, 223, 255}

State :: enum {
	None = 0,
	Menu,
	Settings,
}

fieldsX: f32 = 4
fieldsY: f32 = 4
syncHV: bool
changeSec: f32 = 0.5
opacity: u8 = 255

colors := [5]raylib.Color {
	{144, 252, 249, opacity},
	{255, 188, 66, opacity},
	{179, 151, 230, opacity},
	{237, 106, 94, opacity},
	{55, 119, 113, opacity},
}

colorIndexes: [dynamic]int
deltaTime: f32

gState: State = State.Menu

main :: proc() {
	fmt.println("Starting...")

	raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "PopGrid")
	raylib.SetTargetFPS(60)
	raylib.SetWindowState(raylib.ConfigFlags{.VSYNC_HINT, .WINDOW_RESIZABLE})
	defer raylib.CloseWindow()

	raylib.GuiSetStyle(
		c.int(raylib.GuiControl.DEFAULT),
		c.int(raylib.GuiDefaultProperty.TEXT_SIZE),
		20,
	)

	myrand: rand.Rand
	rand.init(&myrand, u64(time.time_to_unix_nano(time.now())))

	for !raylib.WindowShouldClose() {
		raylib.BeginDrawing()

		if syncHV {
			fieldsY = fieldsX
		}

		cw := raylib.GetScreenWidth()
		ch := raylib.GetScreenHeight()

		raylib.ClearBackground(bkg)

		#partial switch gState {
		case State.Menu:
			gState = menu(cw, ch)

		case State.Settings:
			gState = settings(cw, ch)
			deltaTime = 0

		case State.None:
			if deltaTime == 0 {
				randomizeColors(cw, ch, &myrand)
			}
			gState = drawTiles(cw, ch, &myrand)

			deltaTime += raylib.GetFrameTime()
			if deltaTime > changeSec {
				deltaTime = 0
			}
		}

		raylib.EndDrawing()
	}
}

menu :: proc(cw, ch: i32) -> State {
	renderTextCenter(cw, 40, "pop.grid", 35)
	renderTextCenter(cw, 100, "a generative art experiment", 15)
	renderTextCenter(cw, ch - 40, "press space to start", 15)

	switch {
	case raylib.IsKeyPressed(raylib.KeyboardKey.SPACE):
		fallthrough
	case raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT):
		return State.None
	}

	return State.Menu
}

settings :: proc(cw, ch: i32) -> State {
	raylib.ClearBackground(bkg)

	raylib.GuiLabel(raylib.Rectangle{x = 30, y = 30, width = 100, height = 30}, "settings")

	sliderText := "%i horizontal tiles"
	if syncHV {
		sliderText = "%i tiles"
	}

	raylib.GuiSliderBar(
		raylib.Rectangle{x = 30, y = 80, width = 150, height = 30},
		"",
		fmt.ctprintf(sliderText, int(fieldsX)),
		&fieldsX,
		2,
		20,
	)

	if !syncHV {
		raylib.GuiSliderBar(
			raylib.Rectangle{x = 30, y = 140, width = 150, height = 30},
			"",
			fmt.ctprintf("%i vertical tiles", int(fieldsY)),
			&fieldsY,
			2,
			20,
		)
	}

	raylib.GuiCheckBox(
		raylib.Rectangle{x = 30, y = 190, width = 20, height = 20},
		"sync horizontal and vertical",
		&syncHV,
	)

	raylib.GuiSlider(
		raylib.Rectangle{x = 30, y = 230, width = 150, height = 30},
		"",
		fmt.ctprintf("change every %.02fs", changeSec),
		&changeSec,
		0.05,
		1,
	)

	if raylib.GuiButton(
		   raylib.Rectangle{x = 30, y = f32(ch) - 60, width = 60, height = 30},
		   "back",
	   ) {
		return State.None
	}

	return State.Settings
}

drawTiles :: proc(cw, ch: i32, r: ^rand.Rand) -> State {
	hsize := cw / i32(fieldsX)
	vsize := ch / i32(fieldsY)

	opacity = 255
	index := 0
	for x: i32 = 0; x < cw; x += hsize {
		for y: i32 = 0; y < ch; y += vsize {
			colors[colorIndexes[index]].a = opacity
			raylib.DrawRectangle(x, y, hsize - 10, vsize - 10, colors[colorIndexes[index]])
			index += 1
		}
	}

	opacity = 100
	index = 0
	for x: i32 = 0; x < cw; x += hsize {
		for y: i32 = 0; y < ch; y += vsize {
			colors[colorIndexes[index]].a = opacity
			raylib.DrawRectangle(
				x + 25 - i32(fieldsX),
				y + 25 - i32(fieldsY),
				hsize,
				vsize,
				colors[colorIndexes[index]],
			)
			index += 1
		}
	}

	raylib.DrawText(
		raylib.TextFormat("CX:%i | CY:%i | W:%i | H:%i", i32(fieldsX), i32(fieldsY), cw, ch),
		20,
		ch - 20,
		15,
		raylib.BLACK,
	)

	switch {
	case raylib.IsKeyPressed(raylib.KeyboardKey.SPACE):
		return State.Settings
	}

	return State.None
}

randomizeColors :: proc(cw, ch: i32, r: ^rand.Rand) {
	clear(&colorIndexes)

	for i: i32 = 0; i <= i32(fieldsX) * i32(fieldsY) * 2; i += 1 {
		index := rand.int63(r) % 4
		append(&colorIndexes, int(index))
	}
}

renderTextCenter :: proc(cw: i32, ypos: i32, text: cstring, fontsize: c.int) {
	raylib.DrawText(
		text,
		cw / 2 - raylib.MeasureText(text, fontsize) / 2,
		ypos,
		fontsize,
		raylib.BLACK,
	)
}
