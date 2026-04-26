# Assembly Key-Value Store Project Guide

## Project Overview
This project implements a simple key-value store in x86-64 assembly language. The system supports basic GET/SET operations with file persistence.

## Current Implementation Analysis

### Strengths:
1. **Modular Design**: Separate files for different components (server, handlers)
2. **File Persistence**: Uses `kv_store.txt` for data storage
3. **Command Parsing**: Basic GET/SET/EXIT command recognition
4. **Memory Management**: Includes buffer clearing routines
5. **Error Handling**: Basic file error detection

### Weaknesses:
1. **Inconsistent String Handling**: Mixed case sensitivity approaches
2. **Limited Error Messages**: Generic "NOT FOUND" messages
3. **Memory Safety**: Potential buffer overflow risks
4. **Concurrency**: No handling for simultaneous access
5. **Performance**: File operations on every GET/SET

### Key Files:
- `server.asm`: Main server loop and command dispatch
- `handle_get.asm`: GET command implementation
- `simple_compare.asm`: Basic command comparison logic
- `kv_store.txt`: Persistent storage file

## Implementation Improvements Needed

### Code Quality:
1. **Consistent String Handling**:
   - Standardize case conversion
   - Proper null termination
   - Whitespace handling

2. **Error Handling**:
   - Specific error messages
   - File operation error codes
   - Input validation

3. **Memory Safety**:
   - Buffer size checks
   - Proper bounds checking
   - Clear memory before use

### Functionality:
1. **Command Parsing**:
   - Handle quoted strings
   - Support spaces in values
   - Validate key formats

2. **File Operations**:
   - Atomic writes
   - File locking
   - Efficient storage format

3. **Performance**:
   - Memory caching
   - Batch operations
   - Compression

## Lessons Learned

### Assembly Best Practices:
1. **Register Management**:
   - Preserve registers across calls
   - Use appropriate registers for syscalls

2. **Memory Handling**:
   - Always null-terminate strings
   - Clear buffers before use
   - Use proper alignment

3. **Syscall Usage**:
   - Check return values
   - Handle errors gracefully
   - Use appropriate flags

### Project Structure:
1. **Modularity**:
   - Separate concerns
   - Reusable components
   - Clear interfaces

2. **Documentation**:
   - Comment complex logic
   - Document syscalls
   - Explain data structures

## Next Steps

### Immediate Improvements:
1. Fix string comparison consistency
2. Add proper error messages
3. Implement atomic file operations

### Medium Term Goals:
1. Add Python/C bindings
2. Implement memory caching
3. Add command-line interface

### Long Term Vision:
1. Network support
2. Transaction support
3. Cluster replication

## Example Commands

Build the project:
```bash
make clean && make
```

Run the server:
```bash
./kvstore_app
```

Test commands:
```bash
echo "SET foo bar" | ./kvstore_app
echo "GET foo" | ./kvstore_app
```

## Resources

1. [Linux Syscall Reference](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md)
2. [NASM Tutorial](https://cs.lmu.edu/~ray/notes/nasmtutorial/)
3. [x86-64 Assembly Guide](https://cs.lmu.edu/~ray/notes/x86assembly/)
4. [Linux File Operations](https://man7.org/linux/man-pages/dir_section_2.html)
