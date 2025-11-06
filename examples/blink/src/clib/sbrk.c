extern char __heapbot; // Defined by the linker
extern char __heaptop; // Defined by the linker

static char* heap_end = &__heapbot;

void* sbrk(int incr) {
    char* prev_heap_end;
    prev_heap_end = heap_end;
    if (heap_end + incr >= &__heaptop) {
        return (void*)0; // usually -1 but not for this malloc implementation
    }
    heap_end += incr;
    return (void*)prev_heap_end;
}
