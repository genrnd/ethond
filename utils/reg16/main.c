#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>
  
#define MAP_SIZE  (4096)
#define MAP_MASK  (MAP_SIZE-1)
#define MEM_FNAME ("/dev/mem")
#define H2F_ADDR  (0xC0000000)

#define USAGE "Usage:\n" \
"%s REG [WRITE_DATA]\n" \
"Output the contents of register REG if no WRITE_DATA is specified.\n" \
"Otherwise, write WRITE_DATA into the register.\n"

int main( int argc, char *argv[] ) 
{
  int return_code = 0;
  int fd;

  if( argc < 2 || argc > 3 ) {
    printf( USAGE, argv[ 0 ] );
    exit( EINVAL );
  }

  uint8_t *map_page_addr, *map_byte_addr; 
  unsigned long raw_data;
  uint16_t reg_idx;
  
  char *rest = '\0'; 
  raw_data = strtoul( argv[ 1 ], &rest, 0 );
  if( *rest || raw_data >= MAP_SIZE ) {
    fprintf(stderr, "Expected register index from 0 to %d; got %s.\n",
        MAP_SIZE - 1, argv[ 1 ]);
    exit( EINVAL );
  }
  reg_idx = raw_data;

  /* MEM_FNAME is a character device file that is an image of the memory. */
  fd = open( MEM_FNAME, O_RDWR | O_SYNC );
  if( fd < 0 ) {
    perror( "open" );
    exit( EBADF ); 
  }

  /* We mmap /dev/mem into our address space and receive the resulting page
   * address. */
  map_page_addr = mmap( 0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd,
      H2F_ADDR );
  if( map_page_addr == MAP_FAILED ) {
    perror( "mmap" );
    return_code = errno;
    goto CLOSE_FD;
  }

  /* Address of a register in bytes relative to the start of memory mapped page
   * is the index of the register times
   * (16 bits per register / 8 bits in a byte = 2). */
  map_byte_addr = map_page_addr + reg_idx * 2;

  uint16_t data;

  /* If the WRITE_DATA argument is present, perform writing into the register.*/
  if( argc == 3 ) {
    raw_data = strtoul( argv[ 2 ], &rest, 0 );
    if ( *rest || raw_data > 0xFFFF ) {
      fprintf( stderr,
          "Expected data to be a number in range of [0; 0xFFFF], got %s\n.",
          argv[ 2 ] );
      return_code = EINVAL;
      goto MUNMAP;
    }
    data = raw_data;

    *( ( uint16_t *) map_byte_addr ) = data;
  } else {
    data = *( ( uint16_t *) map_byte_addr );
    printf( "0x%04x\n", data );
  }

MUNMAP:
  if( munmap( map_page_addr, MAP_SIZE ) ) {
    perror( "munmap" );
    return_code = errno;
  }

CLOSE_FD:
  if( close( fd ) ) {
    perror( "close" );
    return_code = EBADF;
  };
  return return_code;
}
