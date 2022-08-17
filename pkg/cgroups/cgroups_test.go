//go:build !linux
// +build !linux

package cgroups

import (
	"testing"

	"github.com/containers/storage/pkg/unshare"
	spec "github.com/opencontainers/runtime-spec/specs-go"
)

func TestCreated(t *testing.T) {
	// tests only works in rootless mode
	if unshare.IsRootless() {
		return
	}

	var resources spec.LinuxResources
	cgr, err := New("machine.slice", &resources)
	if err != nil {
		t.Error(err)
	}
	if err := cgr.Delete(); err != nil {
		t.Error(err)
	}

	cgr, err = NewSystemd("machine.slice")
	if err != nil {
		t.Error(err)
	}
	if err := cgr.Delete(); err != nil {
		t.Error(err)
	}
}
