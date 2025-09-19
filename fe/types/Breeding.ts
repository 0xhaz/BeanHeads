export const BreedingMode = {
  NewBreed: 0,
  Mutation: 1,
  Fusion: 2,
  Ascension: 3,
} as const;

export type BreedingMode = (typeof BreedingMode)[keyof typeof BreedingMode];

export type BreedRequest = {
  owner: `0x${string}`;
  parent1: bigint;
  parent2: bigint;
  mode: BreedingMode;
};
