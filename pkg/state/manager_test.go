package state

import (
	"testing"
)

func TestStateManager(t *testing.T) {
	sm := NewStateManager()

	// Test Set and Get
	sm.Set("test", "value")
	if val, ok := sm.Get("test"); !ok || val != "value" {
		t.Errorf("Expected value 'value', got %v", val)
	}

	// Test Delete
	sm.Delete("test")
	if _, ok := sm.Get("test"); ok {
		t.Error("Expected key to be deleted")
	}
}

/* 
MIT License

Copyright (c) 2024 @eberil

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
*/