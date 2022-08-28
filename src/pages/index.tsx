/* eslint-disable no-unused-vars */
/* eslint-disable @typescript-eslint/no-unused-vars */
import { Button, Spin } from 'antd';
import { useEffect, useState } from 'react';
import { LoadingOutlined } from '@ant-design/icons';
import { TransactionPayload } from 'aptos/dist/generated';
import { useWallet } from '@manahippo/aptos-wallet-adapter';
import { aptosClient, faucetClient } from '../config/aptosClient';
import { AptosAccount } from 'aptos';
import './index.css';

const MainPage = () => {
  const [txLoading, setTxLoading] = useState(false);
  const [txLinks, setTxLinks] = useState<string[]>([]);
  const {
    connect,
    disconnect,
    account,
    wallets,
    signAndSubmitTransaction,
    connecting,
    connected,
    disconnecting
  } = useWallet();

  const renderWalletConnectorGroup = () => {
    return wallets.map((wallet) => {
      const option = wallet.adapter;
      return (
        <Button
          onClick={() => {
            connect(option.name);
          }}
          id={option.name.split(' ').join('_')}
          key={option.name}
          className="connect-btn">
          {option.name}
        </Button>
      );
    });
  };

  const transferToken = async () => {
    try {
      setTxLoading(true);
      if (account?.address || account?.publicKey) {
        const addressKey = account?.address?.toString() || account?.publicKey?.toString() || '';
        const demoAccount = new AptosAccount();
        // await faucetClient.fundAccount(demoAccount.address(), 10);
        const payload: TransactionPayload = {
          type: 'entry_function_payload',
          function:
            '0x36273dfe66c1620ceeebfb63f6baa9d2893a4ce2d454a554e7f92c2f51504fe3::nft_mint::buy_nft',
          type_arguments: [],
          arguments: []
        };
        const txnRequest = await aptosClient.generateTransaction(addressKey, payload);
        console.log('txnRequest', txnRequest);
        const transactionRes = await signAndSubmitTransaction(payload);
        //await aptosClient.waitForTransaction(transactionRes?.hash || '');
        const links = [...txLinks, `https://explorer.devnet.aptos.dev/txn/${transactionRes?.hash}`];
        setTxLinks(links);
      }
    } catch (err: any) {
      console.log('tx error: ', err);
    } finally {
      setTxLoading(false);
    }
  };

  const renderTxLinks = () => {
    return txLinks.map((link: string, index: number) => (
      <div className="flex gap-2 transaction" key={link}>
        <p>{index + 1}.</p>
        <a href={link} target="_blank" rel="noreferrer" className="underline App-link">
          {link}
        </a>
      </div>
    ));
  };

  const renderContent = () => {
    if (connecting || disconnecting) {
      return <Spin indicator={<LoadingOutlined style={{ fontSize: 48 }} spin />} />;
    }
    if (connected && account) {
      return (
        <div className="flex flex-col gap-2">
          <strong>
            Address: <div id="address">{account?.address?.toString()}</div>
          </strong>
          <strong>
            Public Key: <div id="publicKey">{account?.publicKey?.toString()}</div>
          </strong>
          <Button id="transferBtn" onClick={() => transferToken()} loading={txLoading}>
            Mint NFT
          </Button>
          <Button
            id="disconnectBtn"
            onClick={() => {
              setTxLinks([]);
              disconnect();
            }}>
            Disconnect
          </Button>
          <div className="mt-4">
            <h4>Transaction History:</h4>
            <div className="flex flex-col gap-2">{renderTxLinks()}</div>
          </div>
        </div>
      );
    } else {
      return (
        <div className="flex flex-col gap-4">
          <strong className="header">Select Wallet</strong>
          {renderWalletConnectorGroup()}
        </div>
      );
    }
  };
  return (
    <div className="w-full h-[100vh] flex justify-center items-center background">
      <div className="flex justify-center">{renderContent()}</div>
    </div>
  );
};

export default MainPage;
