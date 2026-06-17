package main

import "core:fmt"
import "core:math"
import "core:sort"
import "core:strings"
import "core:sys/linux"
import "core:sys/posix"
import "core:time"

Screen_Width :: 120
Screen_Height :: 40

Map_Height :: 16
Map_Width :: 16

Field_Of_View :: math.PI / 4
Sight_Depth :: 16.0

main :: proc() {
	stdin_fd := posix.FD(0)

	// obtener configuracion actual
	term: posix.termios
	posix.tcgetattr(stdin_fd, &term)

	defer posix.tcsetattr(stdin_fd, .TCSANOW, &term) // al salir volver a la configuracion original

	raw := term
	raw.c_lflag -= {.ICANON, .ECHO} // desactivar buffer y echo
	raw.c_cc[.VMIN] = 0 // no esperar N bytes minimo
	raw.c_cc[.VTIME] = 0 // sin timeout

	posix.tcsetattr(stdin_fd, .TCSANOW, &raw)


	screen := make([]rune, Screen_Width * Screen_Height)

	for idx in 0 ..< len(screen) {
		screen[idx] = '.'
	}

	player_x := 5.0
	player_y := 5.0
	player_angle := 0.0


	mini_map := strings.builder_make()

	strings.write_string(&mini_map, "################")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#.........######")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "#..............#")
	strings.write_string(&mini_map, "################")

	tp1 := time.now()
	tp2 := time.now()

	// Game loop
	for {
		time.sleep(16 * time.Millisecond)

		tp2 = time.now()
		delta := time.diff(tp1, tp2)
		elapsed_time := time.duration_seconds(delta)

		tp1 = tp2

		// INPUT ======================
		polls_fds := []linux.Poll_Fd{{fd = linux.Fd(0), events = {.IN}}}
		_, poll_err := linux.poll(polls_fds, 0)

		if poll_err == .NONE && .IN in polls_fds[0].revents {
			key_buf: [1]u8

			n, read_err := linux.read(linux.Fd(0), key_buf[:])

			if n > 0 && read_err == .NONE {
				key := key_buf[0]

				switch (key) {
				case 'a', 'A':
					player_angle -= 3 * elapsed_time
				case 'd', 'D':
					player_angle += 3 * elapsed_time
				case 'w', 'W':
					player_x += math.sin_f64(player_angle) * 5.0 * elapsed_time
					player_y += math.cos_f64(player_angle) * 5.0 * elapsed_time

					if mini_map.buf[int(player_y) * Map_Width + int(player_x)] == '#' {
						player_x -= math.sin_f64(player_angle) * 5.0 * elapsed_time
						player_y -= math.cos_f64(player_angle) * 5.0 * elapsed_time
					}

				case 's', 'S':
					player_x -= math.sin_f64(player_angle) * 5.0 * elapsed_time
					player_y -= math.cos_f64(player_angle) * 5.0 * elapsed_time

					if mini_map.buf[int(player_y) * Map_Width + int(player_x)] == '#' {
						player_x += math.sin_f64(player_angle) * 5.0 * elapsed_time
						player_y += math.cos_f64(player_angle) * 5.0 * elapsed_time
					}
				}
			}
		}


		for x in 0 ..< Screen_Width {

			ray_angle :=
				(player_angle - Field_Of_View / 2.0) + (f64(x) / f64(Screen_Width)) * Field_Of_View

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
                        //if (math.acos(distance_dot[2][1]) < bound) do boundary = true
					}
				}
			}

			ceiling := f64(Screen_Height / 2.0) - Screen_Height / distance_to_wall
			floor := Screen_Height - ceiling

			shade := ' '

			if (distance_to_wall <= Sight_Depth / 4.0) do shade = 0x2588
			else if (distance_to_wall < Sight_Depth / 3.0) do shade = 0x2593
			else if (distance_to_wall < Sight_Depth / 2.0) do shade = 0x2592
			else if (distance_to_wall < Sight_Depth) do shade = 0x2591
			else do shade = ' '

            if boundary do shade = ' '

			for y in 0 ..< Screen_Height {
				if f64(y) < ceiling {
					screen[y * Screen_Width + x] = ' '
				} else if f64(y) > ceiling && f64(y) <= floor {
					screen[y * Screen_Width + x] = shade
				} else {
					b := 1.0 - (f64(y) - Screen_Height / 2.0) / (f64(Screen_Height) / 2.0)

					if b < 0.25 do shade = '#'
					else if b < 0.50 do shade = 'x'
					else if b < 0.75 do shade = '.'
					else if b < 0.9 do shade = '-'

					screen[y * Screen_Width + x] = shade
				}
			}
		}

		fmt.printf("%s", "\x1b[H")

        for x in 0 ..< Map_Width {
            for y in 0 ..< Map_Height {
                screen[(y * Screen_Width) + x] = rune(mini_map.buf[int(y) * Map_Width + int(x)])
            }
        }

        screen[int(player_y) * Screen_Width + int(player_x)] = 'P'
		for row in 0 ..< Screen_Height {
			start := row * Screen_Width
			line := screen[start:start + Screen_Width]

			fmt.printf("%s\n", line)
		}

	}

}
