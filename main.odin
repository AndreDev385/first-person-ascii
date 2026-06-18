package main

import "core:math"
import "core:sort"
import "core:strings"
import rl "vendor:raylib"

Window_Width :: 1280
Window_Height :: 720

Grid_Width :: 160
Grid_Height :: 90

Map_Height :: 32
Map_Width :: 32

Field_Of_View :: math.PI / 4
Sight_Depth :: 16.0

main :: proc() {

	rl.InitWindow(Window_Width, Window_Height, "First Person Shooter")
	rl.SetTargetFPS(60)

	cell_w := f32(Window_Width) / Grid_Width
	cell_h := f32(Window_Height) / Grid_Height

	//screen := make([]rune, Grid_Width * Grid_Height)

	//for idx in 0 ..< len(screen) {
	//	screen[idx] = '.'
	//}

	player_x := 2.0
	player_y := 2.0
	player_angle := 0.0


	mini_map := strings.builder_make()

	strings.write_string(&mini_map, "################################")
	strings.write_string(&mini_map, "#...#..........#...............#")
	strings.write_string(&mini_map, "#...#..........#...............#")
	strings.write_string(&mini_map, "#.......#......#..........#....#")
	strings.write_string(&mini_map, "#########......#..........#....#")
	strings.write_string(&mini_map, "#..............#..........#....#")
	strings.write_string(&mini_map, "#...############..........#....#")
	strings.write_string(&mini_map, "#..............#..........#....#")
	strings.write_string(&mini_map, "#..............#.....#....#....#")
	strings.write_string(&mini_map, "#..............#.....######....#")
	strings.write_string(&mini_map, "#..............#.....#.........#")
	strings.write_string(&mini_map, "#.........######.....#.........#")
	strings.write_string(&mini_map, "#....................#....#....#")
	strings.write_string(&mini_map, "#.............########....#....#")
	strings.write_string(&mini_map, "#.............#...........#....#")
	strings.write_string(&mini_map, "#.............#...........#....#")
	strings.write_string(&mini_map, "###############....#############")
	strings.write_string(&mini_map, "#..............................#")
	strings.write_string(&mini_map, "#..............................#")
	strings.write_string(&mini_map, "#..............................#")
	strings.write_string(&mini_map, "#..............................#")
	strings.write_string(&mini_map, "#.........########.....#.......#")
	strings.write_string(&mini_map, "#.........#............#.......#")
	strings.write_string(&mini_map, "#.........#............#.......#")
	strings.write_string(&mini_map, "#.........#............#.......#")
	strings.write_string(&mini_map, "#.........#............#.......#")
	strings.write_string(&mini_map, "#.........#............#.......#")
	strings.write_string(&mini_map, "#.........#####........#.......#")
	strings.write_string(&mini_map, "#.............#........#.......#")
	strings.write_string(&mini_map, "#.............#........#.......#")
	strings.write_string(&mini_map, "#.............#........#.......#")
	strings.write_string(&mini_map, "################################")

	// Game loop
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		elapsed_time := f64(rl.GetFrameTime())

		// INPUT ======================
		if rl.IsKeyDown(.A) {
			player_angle -= 3 * elapsed_time
		}
		if rl.IsKeyDown(.D) {
			player_angle += 3 * elapsed_time
		}
		if rl.IsKeyDown(.W) {
			player_x += math.sin_f64(player_angle) * 3.0 * elapsed_time
			player_y += math.cos_f64(player_angle) * 3.0 * elapsed_time

			if mini_map.buf[int(player_y) * Map_Width + int(player_x)] == '#' {
				player_x -= math.sin_f64(player_angle) * 3.0 * elapsed_time
				player_y -= math.cos_f64(player_angle) * 3.0 * elapsed_time
			}

		}
		if rl.IsKeyDown(.S) {
			player_x -= math.sin_f64(player_angle) * 3.0 * elapsed_time
			player_y -= math.cos_f64(player_angle) * 3.0 * elapsed_time

			if mini_map.buf[int(player_y) * Map_Width + int(player_x)] == '#' {
				player_x += math.sin_f64(player_angle) * 3.0 * elapsed_time
				player_y += math.cos_f64(player_angle) * 3.0 * elapsed_time
			}
		}
		if rl.IsKeyDown(.Q) {
			player_x -= math.cos_f64(player_angle) * 3.0 * elapsed_time
			player_y += math.sin_f64(player_angle) * 3.0 * elapsed_time

			if mini_map.buf[int(player_y) * Map_Width + int(player_x)] == '#' {
				player_x += math.cos_f64(player_angle) * 3.0 * elapsed_time
				player_y -= math.sin_f64(player_angle) * 3.0 * elapsed_time
			}

		}
		if rl.IsKeyDown(.E) {
			player_x += math.cos_f64(player_angle) * 3.0 * elapsed_time
			player_y -= math.sin_f64(player_angle) * 3.0 * elapsed_time

			if mini_map.buf[int(player_y) * Map_Width + int(player_x)] == '#' {
				player_x -= math.cos_f64(player_angle) * 3.0 * elapsed_time
				player_y += math.sin_f64(player_angle) * 3.0 * elapsed_time
			}

		}

		for x in 0 ..< Grid_Width {

			ray_angle :=
				(player_angle - Field_Of_View / 2.0) + (f64(x) / f64(Grid_Width)) * Field_Of_View

			distance_to_wall := 0.0
			hit_wall := false
			boundary := false

			eye_x := math.sin_f64(ray_angle)
			eye_y := math.cos_f64(ray_angle)

			for !hit_wall && distance_to_wall < Sight_Depth {

				distance_to_wall += 0.1

				test_x := int(player_x + eye_x * distance_to_wall)
				test_y := int(player_y + eye_y * distance_to_wall)

				if test_x < 0 || test_x >= Map_Width || test_y < 0 || test_y >= Map_Height {
					hit_wall = true
					distance_to_wall = Sight_Depth
				} else {
					if mini_map.buf[test_y * Map_Width + test_x] == '#' {
						hit_wall = true

						distance_dot := make([dynamic][2]f64, 0)

						for tx in 0 ..< 2 {
							for ty in 0 ..< 2 {
								vy: f64 = f64(test_y) + f64(ty) - player_y
								vx: f64 = f64(test_x) + f64(tx) - player_x

								distance := math.sqrt_f64(vx * vx + vy * vy)
								dot := (eye_x * vx / distance) + (eye_y * vy / distance)

								append(&distance_dot, [2]f64{distance, dot})
							}
						}

						sort.quick_sort_proc(distance_dot[:], proc(a, b: [2]f64) -> int {
							if a[0] < b[0] do return -1
							else if a[0] > b[0] do return 1
							return 0
						})

						bound := 0.01
						if (math.acos(distance_dot[0][1]) < bound) do boundary = true
						if (math.acos(distance_dot[1][1]) < bound) do boundary = true
					}
				}
			}

			gh := f64(Grid_Height)
			ceiling := gh / 2.0 - gh / distance_to_wall
			floor := gh - ceiling

			shade: rl.Color = rl.BLACK

			if (distance_to_wall <= Sight_Depth / 4.0) do shade = rl.Color{255, 255, 255, 255}
			else if (distance_to_wall < Sight_Depth / 3.0) do shade = rl.Color{180, 180, 180, 255}
			else if (distance_to_wall < Sight_Depth / 2.0) do shade = rl.Color{120, 120, 120, 255}
			else if (distance_to_wall < Sight_Depth) do shade = rl.Color{60, 60, 60, 255}
			else do shade = rl.BLACK

			if boundary do shade = ' '

			for y in 0 ..< Grid_Height {
				if f64(y) < ceiling {
					// no need for draw anything
					rl.DrawRectangle(
						i32(x) * i32(cell_w),
						i32(y) * i32(cell_h),
						i32(cell_w),
						i32(cell_h),
						rl.BLACK,
					)
				} else if f64(y) > ceiling && f64(y) <= floor {
					// draw
					rl.DrawRectangle(
						i32(x) * i32(cell_w),
						i32(y) * i32(cell_h),
						i32(cell_w),
						i32(cell_h),
						shade,
					)
				} else {
					b := 1.0 - (f64(y) - gh / 2.0) / (gh / 2.0)

					if b < 0.25 do shade = rl.Color{200, 200, 200, 255}
					else if b < 0.50 do shade = rl.Color{140, 140, 140, 255}
					else if b < 0.75 do shade = rl.Color{80, 80, 80, 255}
					else if b < 0.9 do shade = rl.Color{40, 40, 40, 255}

					// draw
					rl.DrawRectangle(
						i32(x) * i32(cell_w),
						i32(y) * i32(cell_h),
						i32(cell_w),
						i32(cell_h),
						shade,
					)
				}
			}
		}

		// mini map
		for x in 0 ..< Map_Width {
			for y in 0 ..< Map_Height {
				rl.DrawRectangle(
					i32(x) * i32(cell_w),
					i32(y) * i32(cell_h),
					i32(cell_w),
					i32(cell_h),
					shade_to_color(rune(mini_map.buf[y * Map_Width + x])),
				)
			}
		}

		// draw player
		rl.DrawRectangle(
			i32(player_x) * i32(cell_w),
			i32(player_y) * i32(cell_h),
			i32(cell_w),
			i32(cell_h),
			shade_to_color('P'),
		)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

shade_to_color :: proc(ch: rune) -> rl.Color {
	switch ch {
	case 0x2588:
		return rl.Color{255, 255, 255, 255}
	case 0x2593:
		return rl.Color{180, 180, 180, 255}
	case 0x2592:
		return rl.Color{120, 120, 120, 255}
	case 0x2591:
		return rl.Color{60, 60, 60, 255}
	case '#':
		return rl.Color{200, 200, 200, 255}
	case 'x':
		return rl.Color{140, 140, 140, 255}
	case '.':
		return rl.Color{80, 80, 80, 255}
	case '-':
		return rl.Color{40, 40, 40, 255}
	case 'P':
		return rl.Color{0, 255, 0, 255}
	case:
		return rl.Color{0, 0, 0, 255}
	}
}
