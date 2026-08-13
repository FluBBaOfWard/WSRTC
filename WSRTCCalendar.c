// SPDX-License-Identifier: MIT

#include "WSRTCCalendar.h"

static uint8_t fromBcdClamped(uint8_t value, uint8_t minimum, uint8_t maximum) {
    const uint8_t low = value & 0x0F;
    const uint8_t high = value >> 4;
    uint8_t result;

    // The S-3511A corrects invalid writes. Saturating malformed nibbles is
    // deterministic and matches its documented out-of-range correction.
    if (low > 9 || high > 9) {
        return maximum;
    }

    result = (uint8_t)(high * 10 + low);
    if (result < minimum) {
        return minimum;
    }
    if (result > maximum) {
        return maximum;
    }
    return result;
}

static uint8_t toBcd(uint8_t value) {
    return (uint8_t)(((value / 10) << 4) | (value % 10));
}

static uint8_t daysInMonth(uint8_t year, uint8_t month) {
    static const uint8_t days[12] = {
        31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    };
    uint8_t result = days[month - 1];
    if (month == 2 && (year & 3) == 0) {
        result = 29;
    }
    return result;
}

void wsRtcNormalizeDateTime(WSRTCDateTime *dateTime) {
    uint8_t year = fromBcdClamped(dateTime->year, 0, 99);
    uint8_t month = fromBcdClamped(dateTime->month, 1, 12);
    uint8_t day = fromBcdClamped(dateTime->day, 1, daysInMonth(year, month));
    uint8_t weekDay = fromBcdClamped(dateTime->weekDay, 0, 6);
    uint8_t hour = fromBcdClamped(dateTime->hour & 0x3F, 0, 23);
    uint8_t minute = fromBcdClamped(dateTime->minute, 0, 59);
    uint8_t second = fromBcdClamped(dateTime->second, 0, 59);

    dateTime->year = toBcd(year);
    dateTime->month = toBcd(month);
    dateTime->day = toBcd(day);
    dateTime->weekDay = weekDay;
    dateTime->hour = toBcd(hour);
    dateTime->minute = toBcd(minute);
    dateTime->second = toBcd(second);
}

void wsRtcTickDateTime(WSRTCDateTime *dateTime) {
    uint8_t year;
    uint8_t month;
    uint8_t day;
    uint8_t weekDay;
    uint8_t hour;
    uint8_t minute;
    uint8_t second;

    wsRtcNormalizeDateTime(dateTime);
    year = fromBcdClamped(dateTime->year, 0, 99);
    month = fromBcdClamped(dateTime->month, 1, 12);
    day = fromBcdClamped(dateTime->day, 1, daysInMonth(year, month));
    weekDay = dateTime->weekDay;
    hour = fromBcdClamped(dateTime->hour, 0, 23);
    minute = fromBcdClamped(dateTime->minute, 0, 59);
    second = fromBcdClamped(dateTime->second, 0, 59);

    if (++second >= 60) {
        second = 0;
        if (++minute >= 60) {
            minute = 0;
            if (++hour >= 24) {
                hour = 0;
                weekDay = (uint8_t)((weekDay + 1) % 7);
                if (++day > daysInMonth(year, month)) {
                    day = 1;
                    if (++month > 12) {
                        month = 1;
                        year = (uint8_t)((year + 1) % 100);
                    }
                }
            }
        }
    }

    dateTime->year = toBcd(year);
    dateTime->month = toBcd(month);
    dateTime->day = toBcd(day);
    dateTime->weekDay = weekDay;
    dateTime->hour = toBcd(hour);
    dateTime->minute = toBcd(minute);
    dateTime->second = toBcd(second);
}
