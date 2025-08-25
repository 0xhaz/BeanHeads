import React from "react";

const CloseCircularMenu = () => {
  return (
    <div className="relative w-[27px] h-[27px]">
      <div className="absolute top-1/2 left-1/2 w-full h-[3px] bg-white transform -translate-x-1/2 -translate-y-1/2 -rotate-45"></div>
      <div className="absolute top-1/2 left-1/2 w-full h-[3px] bg-white transform -translate-x-1/2 -translate-y-1/2 rotate-45"></div>
    </div>
  );
};

export default CloseCircularMenu;
