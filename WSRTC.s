//
//  WSRTC.s
//  Bandai WonderSwan RTC emulation
//
//  Created by Fredrik Ahlström on 2022-02-12.
//  Copyright © 2022-2025 Fredrik Ahlström. All rights reserved.
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
wsRtcReset:			;@ In r0 = rtcptr, r1=interrupt func
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
	str r1,[rtcptr,#wsRtcState+4]
	str r1,[rtcptr,#wsRtcState+8]
	str r1,[rtcptr,#wsRtcState+12]
	strb r1,[rtcptr,#rtcConfiguration]
	mov r1,#1
	strb r1,[rtcptr,#rtcMonth]
	strb r1,[rtcptr,#rtcDay]
	mov r1,#-1
	strb r1,[rtcptr,#rtcData]
	strb r1,[rtcptr,#rtcPadding0]
	strb r1,[rtcptr,#rtcPadding1]
	bx lr
;@----------------------------------------------------------------------------
wsRtcSaveState:			;@ In r0=destination, r1=rtcptr. Out r0=state size.
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
wsRtcLoadState:			;@ In r0=rtcptr, r1=source. Out r0=state size.
	.type wsRtcLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	add r0,r0,#wsRtcState
	mov r2,#(wsRtcStateEnd-wsRtcState)
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
wsRtcGetStateSize:		;@ Out r0=state size.
	.type wsRtcGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	ldr r0,=(wsRtcStateEnd-wsRtcState)
	bx lr
;@----------------------------------------------------------------------------
wsRtcSetDateTime:				;@ In r0=rtcptr, r1 ??ssMMHH, r2 = ??DDMMYY
	.type wsRtcSetDateTime STT_FUNC
;@----------------------------------------------------------------------------
	strb r2,[rtcptr,#rtcYear]		;@ Year
	mov r2,r2,lsr#8
	strb r2,[rtcptr,#rtcMonth]		;@ Month
	mov r2,r2,lsr#8
	strb r2,[rtcptr,#rtcDay]		;@ Day
	and r2,r1,#0x3F
	strb r2,[rtcptr,#rtcHour]		;@ Hour
	mov r1,r1,lsr#8
	strb r1,[rtcptr,#rtcMinute]		;@ Minute
	mov r1,r1,lsr#8
	strb r1,[rtcptr,#rtcSecond]		;@ Second
	bx lr
;@----------------------------------------------------------------------------
wsRtcUpdate:		;@ r0=rtcptr. Call every second.
	.type wsRtcUpdate STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r1,[rtcptr,#rtcSecond]		;@ Seconds
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x60
	movpl r1,#0
	strb r1,[rtcptr,#rtcSecond]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcMinute]		;@ Minutes
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x60
	movpl r1,#0
	strb r1,[rtcptr,#rtcMinute]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcHour]		;@ Hours
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x24
	movpl r1,#0
	strb r1,[rtcptr,#rtcHour]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcWeekDay]	;@ WeekDay
	add r1,r1,#0x01
	cmp r1,#0x7
	movpl r1,#0
	strb r1,[rtcptr,#rtcWeekDay]

	ldrb r1,[rtcptr,#rtcDay]		;@ Days
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x32
	movpl r1,#1
	strb r1,[rtcptr,#rtcDay]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcMonth]		;@ Months
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x13
	movpl r1,#1
	strb r1,[rtcptr,#rtcMonth]

checkForAlarm:
	ldrb r1,[rtcptr,#rtcConfiguration]	;@ Configuration
	ands r2,r1,#0x2A				;@ Any interrupts enabled?
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
wsRtcStatusR:			;@ r0=rtcptr
	.type wsRtcStatusR STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r1,[rtcptr,#rtcCommand]
	orr r2,r1,#0x80			;@ Ready for reading/writing.
	strb r2,[rtcptr,#rtcCommand]
	mov r0,r1
	bx lr
;@----------------------------------------------------------------------------
wsRtcDataR:				;@ r0=rtcptr
	.type wsRtcDataR STT_FUNC
;@----------------------------------------------------------------------------
	mov r1,#0xFF
;@----------------------------------------------------------------------------
wsRtcDataW:				;@ r0=rtcptr, r1 = value
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
	tst r2,#1
	ldrb r2,[rtcptr,#rtcIndex]
	add r3,r2,#1
	strb r3,[rtcptr,#rtcIndex]
	strbeq r1,[rtcptr,r2]
	ldrb r1,[rtcptr,r2]
	cmp r2,#rtcHour
	beq fixupHour
hourRet:
	mov r2,#0xFF
	strb r2,[rtcptr,#rtcData]
outOfData:
	mov r0,r1
	bx lr

fixupHour:
	cmp r1,#0x12
	orrpl r1,r1,#0x80
	ldrb r2,[rtcptr,#rtcConfiguration]
	movspl r2,r2,lsl#25				;@ #0x40 12/24h
	subpl r1,r1,#0x12
	and r2,r1,#0x0F
	cmp r2,#0x0A
	subpl r1,r1,#0x06
	b hourRet
;@----------------------------------------------------------------------------
wsRtcCommandW:			;@ r0=rtcptr, r1 = value
	.type wsRtcCommandW STT_FUNC
;@----------------------------------------------------------------------------
	and r1,r1,#0x1F
	bic r12,r1,#1			;@ 1=Read/0=Write bit

	mov r2,#rtcPadding0
	mov r3,#-1

	cmp r12,#0x1A			;@ Invalid
	moveq r3,#2

	cmp r12,#0x18			;@ Alarm
	moveq r2,#rtcAlarmH
	moveq r3,#2

	cmp r12,#0x16			;@ Time
	moveq r2,#rtcHour
	moveq r3,#3

	cmp r12,#0x14			;@ DateTime
	moveq r2,#rtcYear
	moveq r3,#7

	cmp r12,#0x12			;@ Configuration register
	moveq r2,#rtcConfiguration
	moveq r3,#1

	cmp r12,#0x10			;@ Reset
	moveq r3,#0
	biceq r1,r1,#0x10
	orreq r1,r1,#0x80		;@ Ready for reading/writing.

	strb r2,[rtcptr,#rtcIndex]
	strb r3,[rtcptr,#rtcLength]
	strb r1,[rtcptr,#rtcCommand]

	beq rtcReset
	tst r1,#1				;@ Read?
	bxne lr
	ldrb r1,[rtcptr,#rtcData]
	cmp r1,#0xFF
	bne wsRtcDataW
	bx lr

#endif // #ifdef __arm__
