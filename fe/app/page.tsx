import MainCard from "@/components/MainCard";
import TransactionList from "@/components/TransactionList";
import { mainTasks } from "@/constants";
import React from "react";

const Page = () => {
  return (
    <div className="p-6">
      <h1 className="text-2xl underline">
        BeanHeads Fully On-Chain NFT Collections
      </h1>
      <section className="home-section mb-5 grid grid-cols-4 gap-4">
        {mainTasks.map(task => (
          <MainCard
            key={task.id}
            id={task.id}
            title={task.title}
            image={task.image}
            description={task.description}
            color={task.color}
          />
        ))}
      </section>
    </div>
  );
};

export default Page;
