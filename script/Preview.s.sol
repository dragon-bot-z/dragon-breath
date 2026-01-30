// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DragonsBreath.sol";

contract PreviewScript is Script {
    function run() public {
        DragonsBreath breath = new DragonsBreath();
        
        // Fire element preview
        console.log("=== FIRE BREATH ===");
        string memory fireSvg = breath.previewBreath(
            0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF,
            0x123456789ABCDEF0123456789ABCDEF0
        );
        console.log(fireSvg);
    }
}
