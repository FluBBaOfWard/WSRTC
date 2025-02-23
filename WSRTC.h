//
//  WSRTC.h
//  Bandai WonderSwan RTC emulation.
//
//  Created by Fredrik Ahlström on 2022-02-12.
//  Copyright © 2022-2025 Fredrik Ahlström. All rights reserved.
//
// Seiko S-3511A RTC behind Luxsor 2003.

#ifndef WSRTC_HEADER
#define WSRTC_HEADER

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	void (*interruptPtr)(bool);
	u8 rtcCommand;
	u8 rtcIndex;
	u8 rtcLength;
	u8 rtcConfiguration;
	u8 rtcYear;
	u8 rtcMonth;
	u8 rtcDay;
	u8 rtcWeekDay;
	u8 rtcHour;
	u8 rtcMinute;
	u8 rtcSecond;
	u8 rtcAlarmHour;
	u8 rtcAlarmMinute;
	u8 rtcData;
	u8 rtcPadding0;
	u8 rtcPadding1;
} WSRTC;

void wsRtcReset(WSRTC *chip, void (*interruptFunc)(bool));

/**
 * Saves the state of the chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The WSRTC chip to save.
 * @return The size of the state.
 */
int wsRtcSaveState(void *destination, const WSRTC *chip);

/**
 * Loads the state of the chip from the source.
 * @param  *chip: The WSRTC chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int wsRtcLoadState(WSRTC *chip, const void *source);

/**
 * Gets the state size of a WSRTC chip.
 * @return The size of the state.
 */
int wsRtcGetStateSize(void);

/**
 * Set the date time of the RTC.
 * @param  *chip: The WSRTC chip to set the time on.
 * @param  time: Second, minute & hour. ??ssMMHH.
 * @param  date: Year, month & day. ??DDMMYY.
 */
void wsRtcSetDateTime(WSRTC *chip, int time, int date);

/**
 * Update the RTC, call every second.
 * @param  *chip: The WSRTC chip to update.
 */
void wsRtcUpdate(WSRTC *chip);

int wsRtcStatusR(WSRTC *chip);
void wsRtcCommandW(WSRTC *chip, int value);
int wsRtcDataR(WSRTC *chip);
void wsRtcDataW(WSRTC *chip, int value);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // WSRTC_HEADER
