// SPDX-License-Identifier: MIT
// Calendar helpers shared by the ARM RTC implementation and host tests.

#ifndef WSRTC_CALENDAR_HEADER
#define WSRTC_CALENDAR_HEADER

#include <stdint.h>

typedef struct {
    uint8_t year;
    uint8_t month;
    uint8_t day;
    uint8_t weekDay;
    uint8_t hour;
    uint8_t minute;
    uint8_t second;
} WSRTCDateTime;

void wsRtcNormalizeDateTime(WSRTCDateTime *dateTime);
void wsRtcTickDateTime(WSRTCDateTime *dateTime);

#endif
