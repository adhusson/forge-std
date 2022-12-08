// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../src/Test.sol";

contract StdChainsTest is Test {
    function testChainRpcInitialization() public {
        // RPCs specified in `foundry.toml` should be updated.
        assertEq(getChain(1).rpcUrl, "https://mainnet.infura.io/v3/7a8769b798b642f6933f2ed52042bd70");
        assertEq(getChain("optimism_goerli").rpcUrl, "https://goerli.optimism.io/");
        assertEq(getChain("arbitrum_one_goerli").rpcUrl, "https://goerli-rollup.arbitrum.io/rpc/");

        // Other RPCs should remain unchanged.
        assertEq(getChain(31337).rpcUrl, "http://127.0.0.1:8545");
        assertEq(getChain("sepolia").rpcUrl, "https://rpc.sepolia.dev");
    }

    // Ensure we can connect to the default RPC URL for each chain.
    function testRpcs() public {
        string memory rpcUrl;
        rpcUrl = vm.rpcUrl("mainnet");
        vm.createSelectFork(rpcUrl);
        rpcUrl = vm.rpcUrl("optimism_goerli");
        vm.createSelectFork(rpcUrl);
        rpcUrl = vm.rpcUrl("arbitrum_one_goerli");
        vm.createSelectFork(rpcUrl);
    }

    function testChainNoDefault() public {
        vm.expectRevert("StdChains getChain(string): Chain alias \"does_not_exist\" not found.");
        getChain("does_not_exist");
    }

    function testChainBubbleUp() public {
        setChain("needs_undefined_env_var", Chain("", 123456789, ""));
        vm.expectRevert(
            "Failed to resolve env var `UNDEFINED_RPC_URL_PLACEHOLDER` in `${UNDEFINED_RPC_URL_PLACEHOLDER}`: environment variable not found"
        );
        getChain("needs_undefined_env_var");
    }

    function testCannotSetChain_ChainIdExists() public {
        setChain("custom_chain", Chain("Custom Chain", 123456789, "https://custom.chain/"));

        vm.expectRevert('StdChains setChain(string,Chain): Chain ID 123456789 already used by "custom_chain".');

        setChain("another_custom_chain", Chain("", 123456789, ""));
    }

    function testSetChain() public {
        setChain("custom_chain", Chain("Custom Chain", 123456789, "https://custom.chain/"));
        Chain memory customChain = getChain("custom_chain");
        assertEq(customChain.name, "Custom Chain");
        assertEq(customChain.chainId, 123456789);
        assertEq(customChain.rpcUrl, "https://custom.chain/");
        Chain memory chainById = getChain(123456789);
        assertEq(chainById.name, customChain.name);
        assertEq(chainById.chainId, customChain.chainId);
        assertEq(chainById.rpcUrl, customChain.rpcUrl);
    }

    function testNoChainId0() public {
        vm.expectRevert("StdChains setChain(string,Chain): chainAlias cannot be the empty string.");
        setChain("", Chain("", 123456789, ""));
    }

    function testNoEmptyAlias() public {
        vm.expectRevert("StdChains setChain(string,Chain): Chain ID 0 cannot be used.");
        setChain("alias", Chain("", 0, ""));
    }

    function testChainIdNotFound() public {
        vm.expectRevert("StdChains getChain(string): Chain alias \"no_such_alias\" not found.");
        getChain("no_such_alias");
    }

    function testChainAliasNotFound() public {
        vm.expectRevert("StdChains getChain(uint): No alias found for chain ID 321.");
        getChain(321);
    }

    function testSetChain_ExistingOne() public {
        setChain("custom_chain", Chain("Custom Chain", 123456789, "https://custom.chain/"));
        assertEq(getChain(123456789).chainId, 123456789);

        setChain("custom_chain", Chain("Modified Chain", 999999999, "https://modified.chain/"));
        vm.expectRevert("StdChains getChain(uint): No alias found for chain ID 123456789.");
        getChain(123456789);

        Chain memory modifiedChain = getChain(999999999);
        assertEq(modifiedChain.name, "Modified Chain");
        assertEq(modifiedChain.chainId, 999999999);
        assertEq(modifiedChain.rpcUrl, "https://modified.chain/");
    }
}