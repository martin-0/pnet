#include <syslog.h>
#include <unistd.h>

int main() {
        syslog(LOG_WARNING, "hello syslog from %d\n", getpid());
        return 0;
}
