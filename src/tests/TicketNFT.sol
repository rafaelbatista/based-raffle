// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TicketNFT
 * @notice NFT tickets for BasedRaffle. Each mint transfers the ticket price to RaffleCore.
 */
contract TicketNFT is ERC721, ERC721Burnable, Ownable {
    uint256 private _nextId;
    uint256 public ticketPrice;
    address public raffleCore;

    event TicketMinted(address indexed buyer, uint256 indexed tokenId, uint256 roundId);

    /**
     * @param name_  ERC721 token name.
     * @param symbol_ ERC721 token symbol.
     * @param price_  Price per ticket (in wei).
     * @param owner_  Initial owner (passed to Ownable).
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price_,
        address owner_
    ) ERC721(name_, symbol_) Ownable(owner_) {
        ticketPrice = price_;
        _nextId = 1;
    }

    /// @notice Set the raffle core contract. Only owner can call.
    function setRaffleCore(address _raffleCore) external onlyOwner {
        raffleCore = _raffleCore;
    }

    /// @notice Mint a ticket for the current round and record the payment.
    /// @param currentRoundId ID of the active round (supplied by RaffleCore).
    /// @return tokenId The newly minted ticket ID.
    function mintTicket(uint256 currentRoundId)
        external
        payable
        returns (uint256 tokenId)
    {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(raffleCore != address(0), "Raffle core not set");

        tokenId = _nextId++;
        _safeMint(msg.sender, tokenId);

        // Transfer the ticket price to the raffle core and record the mint.
        // Using call is the recommended way to transfer ETH.
        (bool ok, ) = raffleCore.call{ value: msg.value }(
            abi.encodeWithSignature("recordMint(uint256)", msg.value)
        );
        require(ok, "recordMint failed");

        emit TicketMinted(msg.sender, tokenId, currentRoundId);
    }
}
