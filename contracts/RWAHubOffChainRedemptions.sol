//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "contracts/RWAHub.sol";
import "contracts/interfaces/IRWAHubOffChainRedemptions.sol";
import "contracts/interfaces/IRWAHubOffChainSubscriptions.sol";

abstract contract RWAHubOffChainRedemptions is
  RWAHub,
  IRWAHubOffChainRedemptions,
  IRWAHubOffChainSubscriptions
{
  // To enable and disable off chain redemptions
  bool public offChainRedemptionPaused;

  // Minimum off chain redemption amount
  uint256 public minimumOffChainRedemptionAmount;

  // To enable and disable off chain subscriptions
  bool public offChainSubscriptionPaused;

  // Minimum off chain subscription amount
  uint256 public minimumOffChainSubscriptionAmount;

  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    address _assetRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount
  )
    RWAHub(
      _collateral,
      _rwa,
      managerAdmin,
      pauser,
      _assetSender,
      _feeRecipient,
      _assetRecipient,
      _minimumDepositAmount,
      _minimumRedemptionAmount
    )
  {
    // Default to the same minimum scription amount as for On-Chain
    // scriptions.
    minimumOffChainSubscriptionAmount = _minimumDepositAmount;

    // Default to the same minimum redemption amount as for On-Chain
    // redemptions.
    minimumOffChainRedemptionAmount = _minimumRedemptionAmount;
  }

  /**
   * @notice Request a redemption to be serviced off chain.
   *
   * @param amountRWATokenToRedeem The requested redemption amount
   * @param offChainDestination    A hash of the destination to which
   *                               the request should be serviced to.
   */
  function requestRedemptionServicedOffchain(
    uint256 amountRWATokenToRedeem,
    bytes32 offChainDestination
  ) external nonReentrant ifNotPaused(offChainRedemptionPaused) {
    if (amountRWATokenToRedeem < minimumOffChainRedemptionAmount) {
      revert RedemptionTooSmall();
    }

    bytes32 redemptionId = bytes32(redemptionRequestCounter++);

    rwa.burnFrom(msg.sender, amountRWATokenToRedeem);

    emit RedemptionRequestedServicedOffChain(
      msg.sender,
      redemptionId,
      amountRWATokenToRedeem,
      offChainDestination
    );
  }

  /**
   * @notice Function to pause off chain redemptoins
   */
  function pauseOffChainRedemption() external onlyRole(PAUSER_ADMIN) {
    offChainRedemptionPaused = true;
    emit OffChainRedemptionPaused(msg.sender);
  }

  /**
   * @notice Function to unpause off chain redemptoins
   */
  function unpauseOffChainRedemption() external onlyRole(MANAGER_ADMIN) {
    offChainRedemptionPaused = false;
    emit OffChainRedemptionUnpaused(msg.sender);
  }

  /**
   * @notice Admin Function to set the minimum off chain redemption amount
   *
   * @param _minimumOffChainRedemptionAmount The new minimum off chain
   *                                         redemption amount
   */
  function setOffChainRedemptionMinimum(
    uint256 _minimumOffChainRedemptionAmount
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldMinimum = minimumOffChainRedemptionAmount;
    minimumOffChainRedemptionAmount = _minimumOffChainRedemptionAmount;
    emit OffChainRedemptionMinimumSet(
      oldMinimum,
      _minimumOffChainRedemptionAmount
    );
  }


  /**
   * @notice Request a subscription to be serviced off chain.
   *
   * @param user                   The address of the user who made the deposit
   * @param amount                 The requested subscription amount
   * @param offChainDestination    A hash of the destination to which
   *                               the request should be serviced to.
   */
  function requestSubscriptionServicedOffchain(
    address user,
    uint256 amount,
    bytes32 offChainDestination
  )
    external
    nonReentrant
    onlyRole(MANAGER_ADMIN)
    ifNotPaused(offChainSubscriptionPaused)
    checkRestrictions(user)
  {
    if (amount < minimumDepositAmount) {
      revert DepositTooSmall();
    }

    uint256 feesInCollateral = _getMintFees(amount);
    uint256 depositAmountAfterFee = amount - feesInCollateral;

    // Link the depositor to their deposit ID
    bytes32 depositId = bytes32(subscriptionRequestCounter++);
    depositIdToDepositor[depositId] = Depositor(
      user,
      depositAmountAfterFee,
      0
    );

    emit SubscriptionRequestedServicedOffChain(
      user,
      depositId,
      amount,
      depositAmountAfterFee,
      feesInCollateral,
      offChainDestination
    );
  }


  /**
   * @notice Function to pause off chain scriptions
   */
  function pauseOffChainSubscription() external onlyRole(PAUSER_ADMIN) {
    offChainRedemptionPaused = true;
    emit OffChainSubscriptionPaused(msg.sender);
  }

  /**
   * @notice Function to unpause off chain scriptions
   */
  function unpauseOffChainSubscription() external onlyRole(MANAGER_ADMIN) {
    offChainRedemptionPaused = false;
    emit OffChainSubscriptionUnpaused(msg.sender);
  }

  /**
   * @notice Admin Function to set the minimum off chain subscription amount
   *
   * @param _minimumOffChainSubscriptionAmount The new minimum off chain
   *                                         subscription amount
   */
  function setOffChainSubscriptionMinimum(
    uint256 _minimumOffChainSubscriptionAmount
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldMinimum = minimumOffChainSubscriptionAmount;
    minimumOffChainSubscriptionAmount = _minimumOffChainSubscriptionAmount;
    emit OffChainSubscriptionMinimumSet(
      oldMinimum,
      _minimumOffChainSubscriptionAmount
    );
  }
}
