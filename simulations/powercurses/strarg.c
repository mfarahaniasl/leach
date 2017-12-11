#include <stdlib.h>
#include <string.h>

/*
  strarg("a b c d e f", " ", 1); => a
  strarg("   a   b   ", " ", 2); => b
  strarg(",.a,.b,.c,.", ".,", 3); => c
  strarg("   ,. ;  a... cdef", " ;,.c", 2) => def   (1 would be "a")
*/

char *strarg( const char *str, const char *delims, size_t arg )
{
    char                      *p = 0;
    int                       len;
		      
    if (arg < 1 || !str || !delims)
        return 0;
				      
    while (strchr(delims, *str) && *str++);
					    
    while ( (len = strcspn(str, delims)) && --arg ) {
        str += len;
	while (strchr(delims, *str) && *str++);
    }
									    
    if (!len)
        return NULL;
											    
    p = malloc(len + 1);
    strncpy(p, str, len)[len] = '\0';
    return p;
}
														
