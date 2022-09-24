// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

/// @title Interface for Base Transfer Helper
/// @author sweetman.eth <sweetmantech@gmail.com>
/// @notice This contract provides shared utility for ZORA transfer helpers
interface IBaseTransferHelper {
    /// @notice If a user has approved the module they're calling
    /// @param _user The address of the user
    function isModuleApproved(address _user, address _module)
        external
        view
        returns (bool);
}
