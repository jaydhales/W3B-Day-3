import { AddressLike } from "ethers";
import { ethers } from "hardhat";

async function main() {
  // Contract Addresses
  const uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const sushi = "0x6B3595068778DD592e39A122f4f5a5cF09C90fE2";
  const iInch = "0x111111111117dC0aa78b770fA6A738034120C302"; // 1INCH

  // Users
  const richGuy = "0x3744DA57184575064838BBc87A0FC791F5E39eA2"; // Enough Ethers, sushi and 1Inch
  const richGuySig = await ethers.getImpersonatedSigner(richGuy);

  // Contract Instances
  const uniswapContract = await ethers.getContractAt("IUniswap", uniswap);
  const sushiContract = await ethers.getContractAt("IERC20", sushi);
  const iInchContract = await ethers.getContractAt("IERC20", iInch);

  const factory = await uniswapContract.factory();
  const uniswapFactory = await ethers.getContractAt(
    "IUniswapV2Factory",
    factory
  );

  const pairAddress = await uniswapFactory.getPair(sushi, iInch);

  console.log({ pairAddress });

  const pairContract = await ethers.getContractAt(
    "IUniswapV2Pair",
    pairAddress
  );

  // Custom Function
  const checkAllBalance = async (message: string) => {
    const etherBal = ethers.formatEther(
      await ethers.provider.getBalance(richGuy)
    );
    const sushiBal = ethers.formatEther(await sushiContract.balanceOf(richGuy));
    const iInchBal = ethers.formatEther(await iInchContract.balanceOf(richGuy));
    const liquidityBal = ethers.formatEther(
      await pairContract.balanceOf(richGuy)
    );

    console.log({
      message,
      etherBal,
      sushiBal,
      iInchBal,
      liquidityBal,
    });
  };

  await checkAllBalance("Initial Balance before Interaction");

  // Approval
  const enoughAllowance = ethers.parseEther("10000");
  const approveSushi = await sushiContract
    .connect(richGuySig)
    .approve(uniswap, enoughAllowance);
  const approveIInch = await iInchContract
    .connect(richGuySig)
    .approve(uniswap, enoughAllowance);
  const approveLiquidityPair = await pairContract
    .connect(richGuySig)
    .approve(uniswap, enoughAllowance);

  await approveSushi.wait();
  await approveIInch.wait();
  await approveLiquidityPair.wait();

  // Add Liquidity

  const amountToAdd = ethers.parseEther("625");
  const amountMin = ethers.parseEther("0");
  const aDayFromNow = Math.round(Date.now() / 1000) + 64800;

  const addLiq = await uniswapContract
    .connect(richGuySig)
    .addLiquidity(
      sushi,
      iInch,
      amountToAdd,
      amountToAdd,
      amountMin,
      amountMin,
      richGuy,
      aDayFromNow
    );

  await addLiq.wait();

  await checkAllBalance("Balance after --- addLiquidity() ---");

  // Remove Liquidity
  const minRemoval = ethers.parseEther("0");
  const liquidityBal = await pairContract.balanceOf(richGuy);

  const removeLiq = await uniswapContract
    .connect(richGuySig)
    .removeLiquidity(
      sushi,
      iInch,
      liquidityBal,
      minRemoval,
      minRemoval,
      richGuy,
      aDayFromNow
    );

  await removeLiq.wait();

  await checkAllBalance("Balance after --- removeLiquidity() ---");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
