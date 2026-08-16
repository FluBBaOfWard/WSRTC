//
//  WSRTC.s
//  Bandai WonderSwan RTC emulation
//
//  Created by Fredrik Ahlström on 2022-02-12.
//  Copyright © 2022-2026 Fredrik Ahlström. All rights reserved.
//
// Seiko S-3511A RTC behind Luxsor 2003.
// Based on https://forums.nesdev.org/viewtopic.php?t=21513
#ifdef __arm__

#include "WSRTC.i"

	.global wsRtcReset
	.global wsRtcSetSize
	.global wsRtcWriteByte
	.global wsRtcSaveState
	.global wsRtcLoadState
	.global wsRtcGetStateSize
	.global wsRtcSetDateTime
	.global wsRtcUpdate
	.global wsRtcUpdateFrame

	.global wsRtcStatusR
	.global wsRtcCommandW
	.global wsRtcDataR
	.global wsRtcDataW


	.syntax unified
	.arm

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
wsRtcReset:					;@ In r0 = rtcptr, r1=interrupt func
	.type wsRtcReset STT_FUNC
;@----------------------------------------------------------------------------
	cmp r1,#0
	adreq r1,dummyFunc
	str r1,[rtcptr,#rtcInterruptPtr]
	stmfd sp!,{lr}
	bl rtcReset
;@ After initial power on!
//	mov r1,#0x82
//	strb r1,[rtcptr,#rtcConfiguration]
//	mov r1,#0x80
//	strb r1,[rtcptr,#rtcAlarmH]
	ldmfd sp!,{lr}
dummyFunc:
	bx lr
;@----------------------------------------------------------------------------
rtcReset:
;@----------------------------------------------------------------------------
	mov r1,#0
	str r1,[rtcptr,#wsRtcState]
	str r1,[rtcptr,#wsRtcState+4]
	str r1,[rtcptr,#wsRtcState+8]
	str r1,[rtcptr,#wsRtcState+12]
	mov r1,#1
	strb r1,[rtcptr,#rtcMonth]
	strb r1,[rtcptr,#rtcDay]
	mov r1,#-1
	strb r1,[rtcptr,#rtcData]
	strb r1,[rtcptr,#rtcPadding0]
	strb r1,[rtcptr,#rtcPadding1]
	bx lr
;@----------------------------------------------------------------------------
wsRtcSaveState:				;@ In r0=dest, r1=rtcptr. Out r0=state size.
	.type wsRtcSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	add r1,r1,#wsRtcState
	mov r2,#(wsRtcStateEnd-wsRtcState)
	bl memcpy

	ldmfd sp!,{lr}
	ldr r0,=(wsRtcStateEnd-wsRtcState)
	bx lr
;@----------------------------------------------------------------------------
wsRtcLoadState:				;@ In r0=rtcptr, r1=source. Out r0=state size.
	.type wsRtcLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	add r0,r0,#wsRtcState
	mov r2,#(wsRtcStateEnd-wsRtcState)
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
wsRtcGetStateSize:			;@ Out r0=state size.
	.type wsRtcGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	ldr r0,=(wsRtcStateEnd-wsRtcState)
	bx lr
;@----------------------------------------------------------------------------
wsRtcSetDateTime:			;@ In r0=rtcptr, r1 ??ssMMHH, r2 = ??DDMMYY
	.type wsRtcSetDateTime STT_FUNC
;@----------------------------------------------------------------------------
	strb r2,[rtcptr,#rtcYear]	;@ Year
	mov r2,r2,lsr#8
	strb r2,[rtcptr,#rtcMonth]	;@ Month
	mov r2,r2,lsr#8
	strb r2,[rtcptr,#rtcDay]	;@ Day
	and r2,r1,#0x3F
	strb r2,[rtcptr,#rtcHour]	;@ Hour
	mov r1,r1,lsr#8
	strb r1,[rtcptr,#rtcMinute]	;@ Minute
	mov r1,r1,lsr#8
	strb r1,[rtcptr,#rtcSecond]	;@ Second
	bx lr
;@----------------------------------------------------------------------------
wsRtcUpdate:				;@ r0=rtcptr, r1=cart clocks. Call often.
	.type wsRtcUpdate STT_FUNC
;@----------------------------------------------------------------------------
#ifndef GBA
	ldrb r2,[rtcptr,#rtcCommand]
	orr r2,r2,#0x80				;@ Ready for reading/writing.
	strb r2,[rtcptr,#rtcCommand]
#endif
	ldr r2,[rtcptr,#rtcCycles]
	subs r1,r2,r1
	ldrcc r2,=384000			;@ 1 Second in cart clocks (3072000/8).
	addcc r1,r1,r2
	str r1,[rtcptr,#rtcCycles]
	bxcs lr

	ldrb r1,[rtcptr,#rtcSecond]	;@ Seconds
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x60
	movpl r1,#0
	strb r1,[rtcptr,#rtcSecond]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcMinute]	;@ Minutes
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x60
	movpl r1,#0
	strb r1,[rtcptr,#rtcMinute]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcHour]	;@ Hours
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	and r2,r1,#0x3F
	cmp r2,#0x24
	movpl r1,#0
	strb r1,[rtcptr,#rtcHour]

	bmi checkForAlarm
	stmfd sp!,{lr}
	bl updateDaysMonthsYears
	ldmfd sp!,{lr}

checkForAlarm:
	ldrb r3,[rtcptr,#rtcConfiguration]	;@ Configuration
	ands r2,r3,#0x2A				;@ Any interrupts enabled?
	beq handleAlarm
	ldrb r1,[rtcptr,#rtcSecond]		;@ Seconds
	cmp r1,#0x00
	ldrbeq r1,[rtcptr,#rtcMinute]	;@ RTC Minutes
	ldrbeq r2,[rtcptr,#rtcAlarmM]	;@ ALARM Minutes
	cmpeq r1,r2
	ldrbeq r1,[rtcptr,#rtcHour]		;@ RTC Hours
	ldrbeq r2,[rtcptr,#rtcAlarmH]	;@ ALARM Hours
	cmpeq r1,r2
	movne r2,#0
	moveq r2,#1
handleAlarm:
	ldr r1,[rtcptr,#rtcInterruptPtr]
	mov r0,r2
	bx r1

;@----------------------------------------------------------------------------
updateDaysMonthsYears:
	ldrb r1,[rtcptr,#rtcWeekDay];@ WeekDay
	add r1,r1,#0x01
	cmp r1,#0x7
	movpl r1,#0
	strb r1,[rtcptr,#rtcWeekDay]

	ldrb r1,[rtcptr,#rtcDay]	;@ Days
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
correctDays:
	;@ Calculate days in month
	ldrb r2,[rtcptr,#rtcMonth]
	cmp r2,#2					;@ February?
	ldrbeq r3,[rtcptr,#rtcYear]
	addeq r3,r3,r3,lsr#3		;@ We only need lowest bit of top nybble
	tsteq r3,#3					;@ Check for leap year
	adrne r3,daysInMonth-1
	ldrne r3,[r3,r2]
	moveq r3,#0x29				;@ 29 days in Feb on leap years

	cmp r1,r3
	movhi r1,#1
	strb r1,[rtcptr,#rtcDay]
	bxle lr

	ldrb r1,[rtcptr,#rtcMonth]	;@ Months
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x13
	movpl r1,#1
	strb r1,[rtcptr,#rtcMonth]
	bxmi lr

	ldrb r1,[rtcptr,#rtcYear]	;@ Year
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	and r2,r1,#0xF0
	cmp r2,#0xA0
	addpl r1,r1,#0x60
	strb r1,[rtcptr,#rtcYear]
	bx lr

;@----------------------------------------------------------------------------
daysInMonth:
	.byte 0x31, 0x28, 0x31, 0x30, 0x31, 0x30, 0x31, 0x31, 0x30, 0x31, 0x30, 0x31
	.align 2
;@----------------------------------------------------------------------------
wsRtcStatusR:				;@ r0=rtcptr
	.type wsRtcStatusR STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r1,[rtcptr,#rtcCommand]
#ifdef GBA
	orr r2,r1,#0x80				;@ Ready for reading/writing.
	strb r2,[rtcptr,#rtcCommand]
#endif
	mov r0,r1
	bx lr
;@----------------------------------------------------------------------------
wsRtcDataR:					;@ r0=rtcptr
	.type wsRtcDataR STT_FUNC
;@----------------------------------------------------------------------------
	mov r1,#0xFF
;@----------------------------------------------------------------------------
wsRtcDataW:					;@ r0=rtcptr, r1 = value
	.type wsRtcDataW STT_FUNC
;@----------------------------------------------------------------------------
	strb r1,[rtcptr,#rtcData]
	ldrsb r3,[rtcptr,#rtcLength]
	subs r3,r3,#1
	bmi outOfData
	strb r3,[rtcptr,#rtcLength]
	ldrb r2,[rtcptr,#rtcCommand]
	biceq r2,r2,#0x10
	bic r2,r2,#0x80
	strb r2,[rtcptr,#rtcCommand]
	tst r2,#1				;@ Rd/Wr? 1=Read
	ldrb r2,[rtcptr,#rtcIndex]
	add r3,r2,#1
	strb r3,[rtcptr,#rtcIndex]
	bne readCont
	cmp r2,#rtcData
	bpl fixupRet
	subs r3,r2,#rtcYear
	ldrpl pc,[pc,r3,lsl#2]
	b fixupRet
	.long fixupYear,fixupMonth,fixupDay,fixupWeekDay,fixupHour,fixupMinute,fixupRet,fixupAlarmH,fixupAlarmM
fixupRet:
	strb r1,[rtcptr,r2]
fixupDone:
	mov r2,#0xFF
	strb r2,[rtcptr,#rtcData]
outOfData:
	mov r0,r1
	bx lr

readCont:
	ldrb r1,[rtcptr,r2]
	cmp r2,#rtcHour
	bne outOfData
	cmp r1,#12
	orrpl r1,r1,#0x80		;@ Set AM/PM flag
	ldrb r3,[rtcptr,#rtcConfiguration]	;@ Configuration
	tst r3,#0x40			;@ 24h mode?
	bne outOfData
	tst r1,#0x80
	subne r1,r1,#0x12

	mov r0,r1
	bx lr

;@----------------------------------------------------------------------------
fixupYear:
	and r3,r1,#0x0F
	cmp r3,#0x0A
	andmi r3,r1,#0xF0
	cmpmi r3,#0xA0
	movpl r1,#0
	b fixupRet
;@----------------------------------------------------------------------------
fixupMonth:
	ands r1,r1,#0x1F
	moveq r1,#1
	and r3,r1,#0x0F
	cmp r3,#0x0A
	cmpmi r1,#0x13
	movpl r1,#1
	b fixupRet
;@----------------------------------------------------------------------------
fixupDay:
	ands r1,r1,#0x3F
	moveq r1,#1
	and r3,r1,#0x0F
	cmp r3,#0x0A
	cmpmi r1,#0x32
	movpl r1,#1
	stmfd sp!,{lr}
	bl correctDays
	ldmfd sp!,{lr}
	b fixupDone
;@----------------------------------------------------------------------------
fixupWeekDay:
	and r1,r1,#0x7
	cmp r1,#0x7
	moveq r1,#0
	b fixupRet
;@----------------------------------------------------------------------------
fixupHour:
	and r3,r1,#0x0F
	cmp r3,#0x0A
	movpl r1,#0
	ldrb r3,[rtcptr,#rtcConfiguration]
	tst r3,#0x40				;@ 24h mode?
	bne fix24hMode
	and r3,r1,#0x1F
	cmp r3,#0x12
	movpl r1,#0
	tst r1,#0x80
	addne r1,r3,#0x12
fix24hMode:
	and r1,r1,#0x3F
	cmp r1,#0x24
	movpl r1,#0
	b fixupRet
;@----------------------------------------------------------------------------
fixupMinute:
	and r1,r1,#0x7F
	and r3,r1,#0x0F
	cmp r3,#0x0A
	cmpmi r1,#0x60
	movpl r1,#0
	b fixupRet
;@----------------------------------------------------------------------------
fixupAlarmH:
	b fixupRet
;@----------------------------------------------------------------------------
fixupAlarmM:
	b fixupRet
;@----------------------------------------------------------------------------
wsRtcCommandW:				;@ r0=rtcptr, r1 = value
	.type wsRtcCommandW STT_FUNC
;@----------------------------------------------------------------------------
	and r1,r1,#0x1F
	bic r12,r1,#1				;@ 1=Read/0=Write bit

	mov r2,#rtcPadding0
	mov r3,#-1

	cmp r12,#0x1A				;@ Invalid
	moveq r3,#2

	cmp r12,#0x18				;@ Alarm
	moveq r2,#rtcAlarmH
	moveq r3,#2

	cmp r12,#0x16				;@ Time
	moveq r2,#rtcHour
	moveq r3,#3

	cmp r12,#0x14				;@ DateTime
	moveq r2,#rtcYear
	moveq r3,#7

	cmp r12,#0x12				;@ Configuration register
	moveq r2,#rtcConfiguration
	moveq r3,#1

	cmp r12,#0x10				;@ Reset
	moveq r3,#0
	biceq r1,r1,#0x10
	orreq r1,r1,#0x80			;@ Ready for reading/writing.

	strb r2,[rtcptr,#rtcIndex]
	strb r3,[rtcptr,#rtcLength]
	strb r1,[rtcptr,#rtcCommand]

	beq rtcReset
	tst r1,#1					;@ Read?
	bxne lr
	ldrb r1,[rtcptr,#rtcData]
	cmp r1,#0xFF
	bne wsRtcDataW
	bx lr

#endif // __arm__
