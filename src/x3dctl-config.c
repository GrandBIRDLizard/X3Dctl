#include "x3dctl-common.h"
#include "x3dctl-config.h"

static void trim(char *s)
{
    char *start = s;
    char *end;

    while (*start && isspace((unsigned char)*start))
        start++;

    if (start != s)
        memmove(s, start, strlen(start) + 1);

    if (*s == '\0')
        return;

    end = s + strlen(s) - 1;
    while (end >= s && isspace((unsigned char)*end))
        *end-- = '\0';
}

int config_verify_security(void)
{
    struct stat st;
    if (stat(CONFIG_PATH, &st) != 0)
        return 1;

    if (st.st_uid != 0) {
        fprintf(stderr, "Config must be owned by root\n");
        return 1;
    }

    if (st.st_mode & (S_IWGRP | S_IWOTH)) {
        fprintf(stderr, "Config must not be writable by group/others\n");
        return 1;
    }

    return 0;
}

char *config_query_profile_for_app(const char *app)
{
    if (!app)
        return NULL;

    const char *base = strrchr(app, '/');
    base = base ? base + 1 : app;

    if (config_verify_security() != 0)
        return NULL;

    FILE *f = fopen(CONFIG_PATH, "r");
    if (!f)
        return NULL;

    static char line[512];

    while (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\r\n")] = 0;

        if (line[0] == '#' || line[0] == '\0')
            continue;

        char *eq = strchr(line, '=');
        if (!eq)
            continue;

        *eq = '\0';
        char *key = line;
        char *val = eq + 1;

        trim(key);
        trim(val);

        if (*key == '\0' || *val == '\0')
            continue;

        char *comment = strchr(val, '#');
        if (comment) {
            *comment = '\0';
            trim(val);
        }

        if (*val == '\0')
            continue;

        if (strcmp(key, base) == 0) {
            fclose(f);
            return strdup(val);
        }
    }

    fclose(f);
    return NULL;
}
