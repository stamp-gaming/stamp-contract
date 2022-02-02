// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Stamp is Ownable, ERC1155("https://stamp.games/api/URI/{id}") {
    struct Game {
        string name;
        uint256 gameId;
        uint256 price;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 maticAvailable;
        address owner;
        bool salesActive;
    }

    event GameCreated(Game newGame);
    event GameSold(Game gameSold, address buyer);

    mapping(uint256 => Game) private gameIdToGame;
    mapping(string => uint256) private nameToGameId;
    mapping(address => uint256[]) private addressToBadges;

    uint256 currentGameId = 1;
    uint256 maticWithdraw = 0;

    function createGame(
        string calldata _name,
        uint256 _price,
        uint256 _maxSupply,
        bool _salesActive
    ) public {
        require(nameToGameId[_name] == 0);
        require(bytes(_name).length > 0);
        Game memory newGame = Game(
            _name,
            currentGameId,
            _price,
            _maxSupply,
            0,
            0,
            msg.sender,
            _salesActive
        );
        gameIdToGame[currentGameId] = newGame;
        nameToGameId[_name] = currentGameId;
        currentGameId++;
        emit GameCreated(newGame);
    }

    function buyGame(uint256 _gameId) public payable {
        Game memory wantedGame = gameIdToGame[_gameId];
        require(bytes(wantedGame.name).length > 0);
        require(msg.value >= wantedGame.price);
        require(wantedGame.salesActive);
        if (wantedGame.maxSupply > 0) {
            require(wantedGame.totalSupply < wantedGame.maxSupply);
        }
        _mint(msg.sender, wantedGame.gameId, 1, "");
        gameIdToGame[_gameId].maticAvailable += ((msg.value * 90) / 100);
        maticWithdraw += ((msg.value * 10) / 100);
        gameIdToGame[_gameId].totalSupply++;
        addressToBadges[msg.sender].push(wantedGame.gameId);
        emit GameSold(wantedGame, msg.sender);
    }

    modifier onlyGameOwner(uint256 _gameId) {
        require(gameIdToGame[_gameId].owner == msg.sender);
        _;
    }

    function transferGameOwnership(uint256 _gameId, address _newOwner)
        public
        onlyGameOwner(_gameId)
    {
        gameIdToGame[_gameId].owner = _newOwner;
    }

    function changeGameName(uint256 _gameId, string calldata _newName)
        public
        onlyGameOwner(_gameId)
    {
        require(bytes(_newName).length > 0);
        require(nameToGameId[_newName] == 0);
        gameIdToGame[_gameId].name = _newName;
        nameToGameId[gameIdToGame[_gameId].name] = 0;
        nameToGameId[_newName] = _gameId;
    }

    function changePrice(uint256 _gameId, uint256 _newPrice)
        public
        onlyGameOwner(_gameId)
    {
        gameIdToGame[_gameId].price = _newPrice;
    }

    function changeMaxSupply(uint256 _gameId, uint256 _newMaxSupply)
        public
        onlyGameOwner(_gameId)
    {
        gameIdToGame[_gameId].maxSupply = _newMaxSupply;
    }

    function changeSalesActive(uint256 _gameId, bool _newSalesActive)
        public
        onlyGameOwner(_gameId)
    {
        gameIdToGame[_gameId].salesActive = _newSalesActive;
    }

    function withdrawGameMatic(uint256 _gameId, uint256 _amount)
        public
        onlyGameOwner(_gameId)
    {
        require(gameIdToGame[_gameId].maticAvailable - _amount >= 0);
        gameIdToGame[_gameId].maticAvailable -= _amount;
        payable(gameIdToGame[_gameId].owner).transfer(_amount);
    }

    function getGameById(uint256 _gameId)
        public
        view
        returns (Game memory game)
    {
        return gameIdToGame[_gameId];
    }

    function getGameByName(string _gameName)
        public
        view
        returns (Game memory game)
    {
        return gameIdToGame[nameToGameId[_gameName]];
    }

    function addressBadges(address _user)
        public
        view
        returns (uint256[] memory badges)
    {
        return addressToBadges[_user];
    }

    function withdrawContractMoney(uint256 _amount) public onlyOwner {
        require(maticWithdraw - _amount >= 0);
        payable(owner()).transfer(_amount);
        maticWithdraw -= _amount;
    }
}
