//
//  DefaultAssets.swift
//  SoraPassport
//
//  Created by Ivan Shlyapkin on 10/28/24.
//  Copyright © 2024 Soramitsu. All rights reserved.
//

import Foundation

enum DefaultAssets {
    static let values: [AssetInfo] = [
        AssetInfo(
            id: "0x0200000000000000000000000000000000000000000000000000000000000000",
            symbol: "XOR",
            precision: 18,
            icon: "data:image/svg+xml;charset=utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 22 22' %3E%3Cpath fill='%23E3232C' d='M22,11c0,6.1-4.9,11-11,11S0,17.1,0,11S4.9,0,11,0S22,4.9,22,11z'/%3E%3Cpath fill='%23FFFFFF' d='M5.8,20.7c1.7-2.6,3.5-5.2,5.3-7.8l5.2,7.8c0.3-0.1,0.5-0.3,0.8-0.5s0.5-0.3,0.7-0.5 c-1.9-2.9-3.9-5.8-5.8-8.7h5.8V9.2H12V7.3h5.8V5.5H4.3v1.8h5.8v1.9H4.3V11h5.8l-5.8,8.7C4.5,19.9,4.7,20,5,20.2 C5.3,20.4,5.5,20.6,5.8,20.7z'/%3E%3C/svg%3E",
            displayName: "SORA",
            visible: true
        ),
        AssetInfo(
            id: "0x0200040000000000000000000000000000000000000000000000000000000000",
            symbol: "VAL",
            precision: 18,
            icon: "data:image/png;base64,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",
            displayName: "SORA Validator Token",
            visible: true
        ),
        AssetInfo(
            id: "0x0200050000000000000000000000000000000000000000000000000000000000",
            symbol: "PSWAP",
            precision: 18,
            icon: "data:image/svg+xml;charset=utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 22 22'%3E%3Cpath fill='%23ED145B' d='M11,0C4.9,0,0,4.9,0,11s4.9,11,11,11s11-4.9,11-11S17.1,0,11,0z'/%3E%3Cpath fill='%23FFFFFF' d='M16,6.1c0.7,0.7,0.7,1.7,0,2.4c-0.7,0.7-4.4,2-4.4,2s1.4-3.8,2-4.4S15.3,5.4,16,6.1z M11,1.8 c0.9,0,1.7,0.8,1.7,1.7C12.7,4.5,11,10,11,10S9.3,4.5,9.3,3.5C9.3,2.6,10.1,1.8,11,1.8z M6.1,6.1c0.7-0.7,1.7-0.7,2.4,0 c0.7,0.7,2,4.4,2,4.4s-3.8-1.4-4.4-2C5.4,7.8,5.4,6.7,6.1,6.1z M1.8,11c0-0.9,0.8-1.7,1.7-1.7S10,11,10,11s-5.5,1.7-6.5,1.7 S1.8,11.9,1.8,11z M6.1,15.9c-0.7-0.7-0.7-1.7,0-2.4c0.7-0.7,4.4-2,4.4-2s-1.4,3.8-2,4.4C7.8,16.6,6.8,16.6,6.1,15.9z M11,20.2 c-0.9,0-1.7-0.8-1.7-1.7S11,12,11,12s1.7,5.5,1.7,6.5S11.9,20.2,11,20.2z M16,15.9c-0.7,0.7-1.7,0.7-2.4,0c-0.7-0.7-2-4.4-2-4.4 s3.8,1.4,4.4,2C16.6,14.2,16.6,15.3,16,15.9z M18.5,12.7C17.5,12.7,12,11,12,11s5.5-1.7,6.5-1.7c0.9,0,1.7,0.8,1.7,1.7 C20.2,11.9,19.4,12.7,18.5,12.7z'/%3E%3C/svg%3E",
            displayName: "Polkaswap",
            visible: true
        ),
        AssetInfo(
            id: "0x0200050000000000000000000000000000000000000000000000000000000000",
            symbol: "PSWAP",
            precision: 18,
            icon: "data:image/svg+xml;charset=utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 22 22'%3E%3Cpath fill='%23ED145B' d='M11,0C4.9,0,0,4.9,0,11s4.9,11,11,11s11-4.9,11-11S17.1,0,11,0z'/%3E%3Cpath fill='%23FFFFFF' d='M16,6.1c0.7,0.7,0.7,1.7,0,2.4c-0.7,0.7-4.4,2-4.4,2s1.4-3.8,2-4.4S15.3,5.4,16,6.1z M11,1.8 c0.9,0,1.7,0.8,1.7,1.7C12.7,4.5,11,10,11,10S9.3,4.5,9.3,3.5C9.3,2.6,10.1,1.8,11,1.8z M6.1,6.1c0.7-0.7,1.7-0.7,2.4,0 c0.7,0.7,2,4.4,2,4.4s-3.8-1.4-4.4-2C5.4,7.8,5.4,6.7,6.1,6.1z M1.8,11c0-0.9,0.8-1.7,1.7-1.7S10,11,10,11s-5.5,1.7-6.5,1.7 S1.8,11.9,1.8,11z M6.1,15.9c-0.7-0.7-0.7-1.7,0-2.4c0.7-0.7,4.4-2,4.4-2s-1.4,3.8-2,4.4C7.8,16.6,6.8,16.6,6.1,15.9z M11,20.2 c-0.9,0-1.7-0.8-1.7-1.7S11,12,11,12s1.7,5.5,1.7,6.5S11.9,20.2,11,20.2z M16,15.9c-0.7,0.7-1.7,0.7-2.4,0c-0.7-0.7-2-4.4-2-4.4 s3.8,1.4,4.4,2C16.6,14.2,16.6,15.3,16,15.9z M18.5,12.7C17.5,12.7,12,11,12,11s5.5-1.7,6.5-1.7c0.9,0,1.7,0.8,1.7,1.7 C20.2,11.9,19.4,12.7,18.5,12.7z'/%3E%3C/svg%3E",
            displayName: "Polkaswap",
            visible: true
        ),
        AssetInfo(
            id: "0x0200060000000000000000000000000000000000000000000000000000000000",
            symbol: "DAI",
            precision: 18,
            icon: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 40 40'%3E%3ClinearGradient id='SVGID_1_' gradientUnits='userSpaceOnUse' x1='5.857' y1='7.857' x2='34.143' y2='36.143' gradientTransform='matrix(1 0 0 -1 0 42)'%3E%3Cstop offset='0' style='stop-color:%23F9AF1A'/%3E%3Cstop offset='1' style='stop-color:%23FBC349'/%3E%3C/linearGradient%3E%3Cpath fill='url(%23SVGID_1_)' d='M20,0c11,0,20,9,20,20s-9,20-20,20S0,31,0,20S9,0,20,0z'/%3E%3Cpath fill='%23FFFFFF' d='M31.9,16.7h-2.4c-1.3-3.6-4.8-6.2-8.8-6.2h-8.2v6.2H9.8v2.2h2.6v2.3H9.8v2.2h2.6v6.1h8.2 c4,0,7.5-2.5,8.8-6.1h2.4v-2.2H30c0-0.4,0.1-0.8,0.1-1.2l0,0c0-0.4,0-0.7-0.1-1.1h1.9L31.9,16.7L31.9,16.7L31.9,16.7z M14.6,12.6h6 c2.9,0,5.3,1.7,6.5,4.1H14.6V12.6z M20.6,27.4h-6v-4H27C25.9,25.7,23.4,27.4,20.6,27.4z M27.8,19.8v0.3c0,0.4,0,0.7-0.1,1H14.6v-2.3 h13.1C27.8,19.2,27.8,19.5,27.8,19.8z'/%3E%3C/svg%3E",
            displayName: "Dai",
            visible: true
        ),
        AssetInfo(
            id: "0x0200070000000000000000000000000000000000000000000000000000000000",
            symbol: "ETH",
            precision: 18,
            icon: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 40 40'%3E%3Cpath fill='%23FFFFFF' d='M40,20c0,11-9,20-20,20S0,31,0,20S9,0,20,0S40,9,40,20z'/%3E%3Cpolygon fill='%2362678F' points='20,5 29.1,20.1 20,16.2 '/%3E%3Cpolygon fill='%238C92B2' points='10.9,20.1 20,5 20,16.2 '/%3E%3Cpolygon fill='%2362678F' points='20,25.7 10.9,20.1 20,16.2 '/%3E%3Cpolygon fill='%23444971' points='29.1,20.1 20,16.2 20,25.7 '/%3E%3Cpolygon fill='%2362678F' points='20,27.6 29.1,22.2 20,35 '/%3E%3Cpolygon fill='%238C92B2' points='20,27.6 10.9,22.2 20,35 '/%3E%3C/svg%3E",
            displayName: "Ether",
            visible: true
        ),
    ]
}
