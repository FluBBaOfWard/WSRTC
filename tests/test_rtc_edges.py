#!/usr/bin/env python3
"""Exhaustive reference checks for the packed-BCD RTC edge handling."""


DAYS_IN_MONTH = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)


def to_bcd(value):
    return ((value // 10) << 4) | (value % 10)


def assembly_bcd_to_binary(value):
    tens = value >> 4
    ones = value & 0x0F
    return ones + (tens << 3) + (tens << 1)


def assembly_month_to_index(value):
    return value - 6 if value >= 0x10 else value


def assembly_second_tick(value):
    if (value & 0x0F) >= 0x0A or value >= 0x60:
        return 0, False

    value += 1
    if (value & 0x0F) >= 0x0A:
        value += 0x06
    if value >= 0x60:
        return 0, True
    return value, False


def expected_second_tick(value):
    low = value & 0x0F
    high = value >> 4
    if low > 9 or high > 5:
        return 0, False

    second = high * 10 + low
    if second == 59:
        return 0, True
    return to_bcd(second + 1), False


def main():
    checked = 0
    for year in range(100):
        year_bcd = to_bcd(year)
        converted_year = assembly_bcd_to_binary(year_bcd)
        assert converted_year == year

        for month in range(1, 13):
            month_bcd = to_bcd(month)
            assert assembly_month_to_index(month_bcd) == month

            expected_days = DAYS_IN_MONTH[month - 1]
            if month == 2 and year % 4 == 0:
                expected_days = 29

            assembly_days = DAYS_IN_MONTH[month - 1]
            if month == 2 and (converted_year & 3) == 0:
                assembly_days = 29
            assert assembly_days == expected_days

            for second in range(256):
                assert assembly_second_tick(second) == expected_second_tick(second)
                checked += 1

    print(
        "OK: 100 packed-BCD years x 12 months x 256 second bytes "
        f"({checked} combinations)"
    )


if __name__ == "__main__":
    main()
