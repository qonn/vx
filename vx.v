module main

import os
import time
import parse
import gen

fn main() {
	start:= time.now()

	files := os.ls('.') or {
		println(err)
		return
	}

	for file in files {
		if os.is_file(file) && file.ends_with('.vx') {
			input := os.read_file(file) or {
				println(err)
				return
			}

			ast := parse.run(input)
			output := gen.run(ast)

			os.write_file(file.replace('.vx', '.jsx'), output) or {
				println(err)
			}
		}
	}

	track(start, 'main')
}

fn track(start time.Time, name string) {
	elapsed := time.since(start)
	println('all done in $elapsed')
}