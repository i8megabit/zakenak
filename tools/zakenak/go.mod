module github.com/i8megabit/zakenak

go 1.21

require (
    github.com/docker/docker v24.0.7
    github.com/docker/go-units v0.5.0
    github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd
    github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822
    github.com/pkg/errors v0.9.1
    gopkg.in/evanphx/json-patch.v4 v4.12.0
    gopkg.in/inf.v0 v0.9.1
)

// Use replace directive to handle incompatible package
replace github.com/docker/docker => github.com/docker/docker v24.0.7