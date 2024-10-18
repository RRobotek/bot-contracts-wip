
import { ethers } from "hardhat";
import { FactoryBoT, DeviceBoT } from "../typechain-types";
import { expect } from "chai";
import hre from "hardhat";

hre.ethers.getSigner

describe("FactoryBoT and DeviceBoT", function () {
  let factoryBot: FactoryBoT;
  let deviceBot: DeviceBoT;
  let owner: any;
  let client: any;
  let ownerAddress: string;
  let clientAddress: string;

  before(async function () {
    [owner, client] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    clientAddress = await client.getAddress();

    console.log("Owner Address:", ownerAddress);
    console.log("Client Address:", clientAddress);


    const FactoryBoT = await hre.ethers.getContractFactory("FactoryBoT");
    factoryBot = await FactoryBoT.deploy();
    console.log("FactoryBoT deployed to:", await factoryBot.getAddress());
  });

  describe("FactoryBoT", function () {
    describe("Deployment", function () {
      it("Should set the right owner", async function () {
        console.log("Owner:", await factoryBot.owner());
        console.log("ownerAddress:", ownerAddress);
        expect(await factoryBot.owner()).to.equal(ownerAddress);
      });
    });

    describe("Create device", function () {
      let deviceAddress: string;

      it("Should create a new device and return its address", async function () {
        const tx = await factoryBot.createDevice(
          BigInt(3600),
          BigInt(1000),
          "this is a test contract",
          ownerAddress
        );
        
        const receipt = await tx.wait();
        
        if (receipt && receipt.logs) {
          const event = receipt.logs.find(
            (log) => log.fragment && log.fragment.name === 'DeviceCreated'
          );
          
          if (event && event.args) {
            deviceAddress = event.args[0];
            console.log("Created Device Address:", deviceAddress);
            
            expect(deviceAddress).to.be.properAddress;
            
            const isInDevices = await factoryBot.devices(0);
            expect(isInDevices).to.equal(deviceAddress);
          } else {
            throw new Error("DeviceCreated event not found in transaction receipt");
          }
        } else {
          throw new Error("Transaction receipt or logs not available");
        }
      });

      describe("DeviceBoT", function () {
        before(async function () {
          const DeviceBoT = await hre.ethers.getContractFactory("DeviceBoT");
          deviceBot = DeviceBoT.attach(deviceAddress);
        });

        it("Should have correct initial values", async function () {
          const chunkDuration = await deviceBot.chunkDuration();
          const chunkPrice = await deviceBot.chunkPrice();
          const metadata = await deviceBot.metadata();
          const deviceOwner = await deviceBot.owner();

          expect(chunkDuration).to.equal(BigInt(3600));
          expect(chunkPrice).to.equal(BigInt(1000));
          expect(metadata).to.equal("this is a test contract");
          expect(deviceOwner).to.equal(ownerAddress);
        });

        it("Should allow subscription", async function () {
          const duration = BigInt(3600); // 1 hour
          const chunkDuration = await deviceBot.chunkDuration();
          const chunkPrice = await deviceBot.chunkPrice();
          const value = (chunkPrice * duration) / chunkDuration;

          await expect(deviceBot.connect(client).subscribe(duration, { value }))
            .to.emit(deviceBot, "Subscribed")
            .withArgs(clientAddress, duration);

          const subscription = await deviceBot.subscription(clientAddress);
          expect(subscription).to.be.gt(0);
        });

        it("Should generate a key", async function () {
          try {
            const tx = await deviceBot.generateKey();
            const receipt = await tx.wait();
            console.log("Key generated successfully");
          } catch (error) {
            console.error("Error generating key:", error);
            throw error;
          }
        });

        it("Should retrieve a key for subscribed user", async function () {
          try {
            // Check subscription status
            const subscriptionStatus = await deviceBot.getSubscriptionStatus(clientAddress);
            console.log("Subscription status:", subscriptionStatus.toString());
            
            // Get current block timestamp
            const currentTimestamp = await deviceBot.getBlockTimestamp();
            console.log("Current block timestamp:", currentTimestamp.toString());
            
            // Ensure subscription is active
            expect(subscriptionStatus).to.be.gt(currentTimestamp);

            console.log("Attempting to retrieve key...");
            
            // Call getKey as a transaction
            
            const key = await deviceBot.connect(client).getKey({
              from: clientAddress,
            });
            
            console.log("Key:", key);




          } catch (error) {
            console.error("Error in test:", error);
            throw error;
          }
        });

        //it("Should fail to get key for unsubscribed user", async function () {
        //  const [, , unsubscribedUser] = await ethers.getSigners();
        //  await expect(deviceBot.connect(unsubscribedUser).getKey())
        //    .to.be.revertedWith("Subscription expired");
        //});

      });
    });
  });
});
