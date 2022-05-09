#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

unsigned int finclip_set(void);

char *finclip_api_name(unsigned int index);

char *finclip_call(const char *api_name, const char *_input);

void finclip_release(char *data);
