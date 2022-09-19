// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {

    address public cryptoDevTokenAddress;

    constructor (address _CryptoDevToken) ERC20("Manisha LLP Token", "MLP"){
        require(_CryptoDevToken != address(0), "Token address passed is a null address");
        cryptoDevTokenAddress = _CryptoDevToken;
    }

    function getReserve() public view returns (uint){
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint _amount) public payable returns(uint){
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        //if there is no initial reserve then take any supply the user want to add
        if(cryptoDevTokenReserve == 0){
            //transfer the ether from user to the contract
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
        //as the user is adding eth for the first time in the contract so the eth balance of the contract is the liquidity(LP TOken) we need to provide him
        liquidity = ethBalance;
        _mint(msg.sender, liquidity);
        }else{
            //now the reserve is not empty so take any amount of eth supplied and determine how many mj token need to be supplied acc to the ratio to prevent the large price impacts because of the addition liquidity
            uint ethReserve = ethBalance - msg.value;

            uint cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve)/ (ethReserve);
            require(_amount >= cryptoDevTokenAmount, "Amount of Tokens sent is less than the minimum tokens require");

            cryptoDevToken.transferFrom(msg.sender, address(this), cryptoDevTokenAmount);

            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);

        }
        return liquidity;
    }

    function removeLiquidity(uint _amount) public returns(uint, uint) {
        require(_amount > 0, "Amount should be grater than 0");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();

        uint ethAmount = (ethReserve * _amount) / _totalSupply;
        uint cryptoDevTokenAmount = (getReserve() * _amount) / _totalSupply;

        _burn(msg.sender, _amount);

        payable(msg.sender).transfer(ethAmount);

        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
        return (ethAmount,cryptoDevTokenAmount); 
    }

    function getAmountOfTokens(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns(uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid Reserves");

        uint256 inputAmountWithFee = inputAmount * 99;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    //swaps ether for tokens
    function ethToTokenSwap(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();

        uint256 tokenBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokenBought >= _minTokens, "Insufficient Balance");

        ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokenBought);
    }

    //swaps token for ether
    function tokenToEthSwap(uint _tokenSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();

        uint256 ethBought = getAmountOfTokens (
            _tokenSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "Insufficient output amount");

        ERC20(cryptoDevTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenSold
       );
       payable(msg.sender).transfer(ethBought);
    }
}