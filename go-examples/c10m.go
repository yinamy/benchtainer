package main

// Benchmark that stresses goroutine allocation and starting. It creates
// a large number of goroutines, each using a small amount of stack, and repeatedly
// yields to them to do some work. It allocates 10K fibers, then runs a loop
// where for a given fiber it resumes it twice to run it through and then frees
// and reallocates it. It does that 10.01M times in total.

const PRINT = false

func maybe_print(str string) {
	if PRINT {
		print(str)
	}
}

const total_conn = 10 * 1000000
const ACTIVE_CONN = 10000
const stack_kb = 32

func stack_use(totalkb int32) int32 {
	// The C version uses some cheeky way of touching specific bytes to page in the
	// stack, rather than allocating heap memory like this. I'm not sure what all the
	// implications of that are. FIXME!
	var x = make([]byte, totalkb*1024)
	result := int32(0)
	for i := range totalkb {
		result += int32(x[i])
	}
	return result + 1
}

func async_worker(driver chan int32, finished chan int32) {
	kb := <-driver
	result := stack_use(kb)
	finished <- result
}

func async_wl() int32 {
	driver := make(chan int32, 10000)
	finished := make(chan int32, 10000)

	maybe_print("async_test1M set up...\n")
	for range ACTIVE_CONN {
		go async_worker(driver, finished)
	}

	count := int32(0)
	for i := range total_conn {
		driver <- stack_kb

		// Clean up and allocate new fiber--don't allocate if we're on the last round.
		if i+ACTIVE_CONN < total_conn {
			go async_worker(driver, finished)
		}
	}
	for true {
		x, more := <-finished
		if !more {
			break
		}
		count += x
	}
	return count
}

func main() {
	result := async_wl()
	if !(result == 10000000) {
		print("result validation failed (result=)", result)
	}
}
