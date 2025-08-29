import TransactionList from "@/components/TransactionList";
import React from "react";

const Transactions = () => {
  return (
    <section className="home-section">
      <TransactionList
        title="Recent Transactions"
        transactions={[]}
        classNames="w-full"
      />
    </section>
  );
};

export default Transactions;
