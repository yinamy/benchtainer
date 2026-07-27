// Monte Carlo PI estimation

package main

import (
	"math"
	"math/rand"
)

// Parameters
const (
	PRINT_RESULTS bool = false
	NUM_TASKS          = int64(1000)
	// Number of samples taken between yields.
	BATCH_SIZE = 20000
	// Number of batches to run in total. Each fiber will take YIELDS * BATCH_SIZE samples
	YIELDS = 50
)

func monte_carlo(i int64, finished chan bool) {
	inside := 0.0
	total := 0.0

	rng := rand.New(rand.NewSource(0xC0FFEE + i)) // give each thread a different rng
	for range YIELDS {
		for range BATCH_SIZE {
			x := rng.Float32()
			y := rng.Float32()

			dist := float64(x*x + y*y)

			if math.Abs(dist-1.0) < 0.0000000001 || dist < 1.0 {
				inside += 1.0
			}

			// if (i % 1000000 == 1){
			//   print(4.0 * inside/total, "\n")
			// }
			total += 1.0

		}
		if PRINT_RESULTS {
			print((4.0*inside)/total, "\n")
		}

		// This is our "yield" to allow other goroutines to run.
		time.Sleep(1 * time.Millisecond)
	}

	if PRINT_RESULTS {
		print((4.0*inside)/total, "\n")
	}

	finished <- true
}

func main() {
	finished := make(chan bool, NUM_TASKS)
	// Spawn workers.
	for i := range NUM_TASKS {
		go monte_carlo(i, finished)
	}
	for range NUM_TASKS {
		<-finished
	}
}
