package main

import "core:fmt"
import "core:os"
import "core:path/filepath"

FileRegistry :: struct {
	file_ids: map[string]uint,
	file_data: [dynamic]string,
}

make_registry :: proc() -> FileRegistry {
	return FileRegistry {
		file_ids = make(map[string]uint),
		file_data = make([dynamic]string),
	}
}

destroy_registry :: proc(registry: ^FileRegistry) {
	delete(registry.file_ids)
	delete(registry.file_data)
}

FileErr :: enum(u8) {
	None,
	NotAbsPath,
	NotRegistered,
	AlreadyRegistered,
	FileNotFound,
}

add_file_to_registry :: proc(self: ^FileRegistry, abs: string) -> (file_id: uint, err: FileErr) {
	if !filepath.is_abs(abs) {
		file_id = 0
		err = FileErr.NotAbsPath
		return
	}

	exists := abs in self.file_ids
	if exists {
		file_id = 0
		err = FileErr.AlreadyRegistered
		return
	}

	file_data, ok := os.read_entire_file(abs)
	if !ok {
		file_id = 0
		err = FileErr.FileNotFound
		return
	}

	file_str := string(file_data)
	append(&self.file_data, file_str)

	file_id = len(self.file_data) - 1
	self.file_ids[abs] = file_id

	err = FileErr.None
	return
}

get_registry_entry :: proc(self: ^FileRegistry, id: uint) -> string {
	return self.file_data[id]
}
