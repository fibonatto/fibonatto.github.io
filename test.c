#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define MAX(a, b) ((a) > (b) ? (a) : (b))
typedef unsigned long ulong;
typedef struct {
  int x;
  const char *s;
} Point;
typedef int (*fn_t)(int, int);

enum { A = 1, B, C = 0xff };
static int add(int a, int b) { return a + b; }

// main
int main(void) {
  bool ok = true;
  char c = '\n';
  const char *s = "hello\tworld";
  int a = 42, *p = &a, v[] = {1, 2, 3};
  uint64_t n = 0xDEADBEEF;
  double d = 3.14e-2f;
  Point x = {.x = a, .s = s}, y = {0};
  Point *q = &x;
  fn_t f = add;

  if (ok && p && *p > 0)
    x.x = MAX(*p, v[0]);
  else if (!ok || !p)
    return -1;

  for (size_t i = 0; i < sizeof(v) / sizeof(*v); ++i)
    v[i] *= 2;

  switch (x.x) {
  case 0:
    goto done;
  case 1 ... 3:
    x.x += (int)d;
    break;
  default:
    x.x = f(x.x, y.x);
  }

  while (q->x--)
    printf("%s %d%c", q->s, q->x, c);
done:
  return x.x ? 0 : 1;
}
