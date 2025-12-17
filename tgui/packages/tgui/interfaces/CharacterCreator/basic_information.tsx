/**
 * Basic character information component for the character creator
 * Backend sibling: code/modules/client/preference/character_creator/basic_information.dm
 */

import { Box, Button, Input, Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';

interface BasicInformationData {
  real_name: string;
  age: number;
  gender: string;
  available_genders: string[];
}

interface BasicInformationProps {
  data: BasicInformationData;
}

export const BasicInformation = (props: BasicInformationProps) => {
  const { act } = useBackend();
  const { data } = props;
  const { real_name, age, gender, available_genders } = data;

  return (
    <Stack fill vertical>
      {/* Name Field */}
      <Stack.Item>
        <Stack align="center">
          <Stack.Item basis="80px">
            <Box fontSize="12px" color="#ccc" textAlign="right" mr={1}>
              Name:
            </Box>
          </Stack.Item>
          <Stack.Item grow>
            <Input
              placeholder="Enter name..."
              value={real_name}
              width="100%"
              onChange={(value) =>
                act('set_name', {
                  name: value,
                })
              }
            />
          </Stack.Item>
          <Stack.Item>
            <Button icon="dice" tooltip="Random Name" compact onClick={() => act('random_name')} />
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Age Field */}
      <Stack.Item mt={1}>
        <Stack align="center">
          <Stack.Item basis="80px">
            <Box fontSize="12px" color="#ccc" textAlign="right" mr={1}>
              Age:
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Input
              placeholder="Age"
              value={age.toString()}
              width="60px"
              textAlign="center"
              onChange={(value) =>
                act('set_age', {
                  age: parseInt(value) || 18,
                })
              }
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Gender Field */}
      <Stack.Item mt={1}>
        <Stack align="center">
          <Stack.Item basis="80px">
            <Box fontSize="12px" color="#ccc" textAlign="right" mr={1}>
              Gender:
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Stack>
              {available_genders.map((genderOption) => (
                <Stack.Item key={genderOption} mr={1}>
                  <Button
                    selected={gender === genderOption}
                    compact
                    onClick={() =>
                      act('set_gender', {
                        gender: genderOption,
                      })
                    }
                  >
                    {genderOption}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};
