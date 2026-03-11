from pathlib import Path

from core.pipeline import run_graph_pipeline
from core.rockwell_parser import parse_l5x_source


def test_parser_rockwell_deve_mapear_task_program_e_jsr(tmp_path: Path) -> None:
    l5x_path = tmp_path / 'demo.L5X'
    l5x_path.write_text(
        '''<?xml version="1.0" encoding="UTF-8"?>
<Project TargetType="Controller" TargetSoftware="RSLogix 5000">
  <Controller Name="DemoController">
    <Tasks>
      <Task Name="MainTask">
        <ScheduledPrograms>
          <ScheduledProgram Name="MainProgram" />
        </ScheduledPrograms>
      </Task>
    </Tasks>
    <Programs>
      <Program Name="MainProgram">
        <Routines>
          <Routine Name="MainRoutine" Type="RLL">
            <RLLContent>
              <Rung Number="0">
                <Text><![CDATA[JSR(SubRoutine,0);]]></Text>
              </Rung>
            </RLLContent>
          </Routine>
          <Routine Name="SubRoutine" Type="RLL">
            <RLLContent>
              <Rung Number="0">
                <Text><![CDATA[NOP();]]></Text>
              </Rung>
            </RLLContent>
          </Routine>
        </Routines>
      </Program>
    </Programs>
  </Controller>
</Project>
''',
        encoding='utf-8',
    )

    blocks = parse_l5x_source(l5x_path)
    payload = run_graph_pipeline(l5x_path, vendor='rockwell')

    assert any(block.block_type == 'Task' and block.name == 'MainTask' for block in blocks)
    assert any(block.block_type == 'MainProgram' and block.name == 'MainProgram' for block in blocks)
    assert any(block.block_type == 'Routine' and block.name == 'MainRoutine' for block in blocks)
    assert any(edge['label'] == 'Routine SubRoutine' for edge in payload['edges'])
    assert payload['vendor'] == 'rockwell'
