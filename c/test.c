#include <assert.h>
#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "oidc4ci.h"

int main() {
  const char *version = oidc4ci_get_version();
  assert(version != NULL);
  assert(strlen(version) > 0);
}
