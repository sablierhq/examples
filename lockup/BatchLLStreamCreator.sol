// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Broker, LockupLinear } from "@sablier/lockup/src/types/DataTypes.sol";
import { ISablierBatchLockup } from "@sablier/lockup/src/interfaces/ISablierBatchLockup.sol";
import { BatchLockup } from "@sablier/lockup/src/types/DataTypes.sol";

contract BatchLLStreamCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // See https://docs.sablier.com/guides/lockup/deployments for all deployments
    ISablierLockup public constant LOCKUP = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);
    ISablierBatchLockup public constant BATCH_LOCKUP = ISablierBatchLockup(0x3F6E8a8Cffe377c4649aCeB01e6F20c60fAA356c);

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function batchCreateStreams(uint128 perStreamAmount) public returns (uint256[] memory streamIds) {
        // Create a batch of two streams
        uint256 batchSize = 2;

        // Calculate the combined amount of DAI tokens to transfer to this contract
        uint256 transferAmount = perStreamAmount * batchSize;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), transferAmount);

        // Approve the Batch contract to spend DAI
        DAI.approve({ spender: address(BATCH_LOCKUP), value: transferAmount });

        // Declare the first stream in the batch
        BatchLockup.CreateWithDurationsLL memory stream0;
        stream0.sender = address(0xABCD); // The sender to stream the tokens, he will be able to cancel the stream
        stream0.recipient = address(0xCAFE); // The recipient of the streamed tokens
        stream0.totalAmount = perStreamAmount; // The total amount of each stream, inclusive of all fees
        stream0.cancelable = true; // Whether the stream will be cancelable or not
        stream0.transferable = false; // Whether the recipient can transfer the NFT or not
        stream0.durations = LockupLinear.Durations({
            cliff: 4 weeks, // Tokens will start streaming continuously after 4 weeks
            total: 52 weeks // Setting a total duration of ~1 year
         });
        stream0.unlockAmounts = LockupLinear.UnlockAmounts({
            start: 0, // Whether the stream will unlock a certain amount of tokens at the start time
            cliff: 0 // Whether the stream will unlock a certain amount of tokens at the cliff time
         });
        stream0.broker = Broker(address(0), ud60x18(0)); // Optional parameter left undefined

        // Declare the second stream in the batch
        BatchLockup.CreateWithDurationsLL memory stream1;
        stream1.sender = address(0xABCD); // The sender to stream the tokens, he will be able to cancel the stream
        stream1.recipient = address(0xBEEF); // The recipient of the streamed tokens
        stream1.totalAmount = perStreamAmount; // The total amount of each stream, inclusive of all fees
        stream1.cancelable = false; // Whether the stream will be cancelable or not
        stream1.transferable = false; // Whether the recipient can transfer the NFT or not
        stream1.durations = LockupLinear.Durations({
            cliff: 1 weeks, // Tokens will start streaming continuously after 4 weeks
            total: 26 weeks // Setting a total duration of ~6 months
         });
        stream1.unlockAmounts = LockupLinear.UnlockAmounts({
            start: 0, // Whether the stream will unlock a certain amount of tokens at the start time
            cliff: 0 // Whether the stream will unlock a certain amount of tokens at the start time
         });
        stream1.broker = Broker(address(0), ud60x18(0)); // Optional parameter left undefined

        // Fill the batch param
        BatchLockup.CreateWithDurationsLL[] memory batch = new BatchLockup.CreateWithDurationsLL[](batchSize);
        batch[0] = stream0;
        batch[1] = stream1;

        streamIds = BATCH_LOCKUP.createWithDurationsLL(LOCKUP, DAI, batch);
    }
}
